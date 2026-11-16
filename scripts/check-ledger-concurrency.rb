# Use a disposable, empty test database; bin/check-ledger-concurrency supplies one.
abort "Disposable test database required" unless Rails.env.test? && ENV["SEOS_CONCURRENCY_CHECK"] == "1" && !User.exists?

def concurrently(*items, &operation)
  ready, start = Queue.new, Queue.new
  threads = items.map do |item|
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ready << true
        start.pop
        operation.call(item)
      end
    end
  end
  items.size.times { ready.pop }
  items.size.times { start << true }
  threads.map(&:value)
end

payer, first, second = 3.times.map do |index|
  User.create!(email: "ledger#{index}@concurrency.test", password: "DisposableTestPassword!42", status: "active", confirmed_at: Time.current, email_notifications: false)
end
debit = PointAccount.for!(payer)
Points::Ledger.post!(debit: PointAccount.system!, credit: debit, amount: 50, key: "funding", kind: "admin_adjustment", source: payer, reason: "Test")
results = concurrently(first, second) do |recipient|
  Points::Ledger.post!(debit: PointAccount.for!(payer), credit: PointAccount.for!(recipient), amount: 40,
    key: "spend:#{recipient.id}", kind: "service_transfer", source: payer, reason: "Test")
  :committed
rescue Exchanges::Invalid
  :rejected
end
raise "Concurrent overspend" unless results.sort == [ :committed, :rejected ] && debit.reload.balance == 10
concurrently(first, first) do |recipient|
  Points::Ledger.post!(debit: PointAccount.system!, credit: PointAccount.for!(recipient), amount: 5,
    key: "same-reward", kind: "achievement_reward", source: payer, reason: "Test")
end
raise "Duplicate reward" unless PointOperation.where(idempotency_key: "same-reward").count == 1

before = [ PointAccount.order(:id).pluck(:balance), PointEntry.count, PointOperation.count ]
begin
  PointOperation.transaction do
    operation = PointOperation.create!(kind: "admin_adjustment", source: payer, idempotency_key: "incomplete", reason: "Test")
    account = PointAccount.system!
    operation.point_entries.create!(point_account: account, amount: -1, balance_after: account.balance - 1)
    operation.update!(status: "committed", committed_at: Time.current)
  end
  raise "Unbalanced operation committed"
rescue ActiveRecord::RecordInvalid
  raise "Partial ledger survived rollback" unless before == [ PointAccount.order(:id).pluck(:balance), PointEntry.count, PointOperation.count ]
end
raise "Unbalanced ledger" unless PointAccount.sum(:balance).zero? && PointEntry.sum(:amount).zero?
raise "Pending operation" if PointOperation.where(status: "pending").exists?

organization = Organization.create!(name: "Test", slug: "ledger-concurrency", kind: "association", status: "verified")
memberships = [ first, second ].map { |user| organization.organization_memberships.create!(user: user, role: "owner", status: "active") }
results = concurrently(*memberships) do |membership|
  membership.update!(role: "editor")
  :changed
rescue ActiveRecord::RecordInvalid
  :rejected
end
raise "Last owner lost" unless results.sort == [ :changed, :rejected ] && organization.organization_memberships.active.where(role: "owner").count == 1
puts "#{ApplicationRecord.connection.adapter_name}: concurrent spending, idempotency, atomic rollback and last owner verified."
