# Seeds must never enqueue notifications or rewards, including Active Storage jobs.
skip_seed_job = -> { throw :abort }
ActiveJob::Base.set_callback(:enqueue, :before, skip_seed_job, prepend: true)
begin
  environment = Rails.env.production? ? "production" : (Rails.env.development? ? "development" : "test")
  load Rails.root.join("db/seeds/#{environment}.rb")
ensure
  ActiveJob::Base.skip_callback(:enqueue, :before, skip_seed_job)
end
