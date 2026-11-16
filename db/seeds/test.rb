# Reference data only, when tests explicitly request db:seed.
%w[discovery point community network].each do |name|
  load Rails.root.join("db/#{name}_seeds.rb")
end
