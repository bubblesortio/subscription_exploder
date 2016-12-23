require "rollbar"

if ENV.has_key?("ROLLBAR_ACCESS_TOKEN")
  Rollbar.configure do |config|
    config.access_token = ENV.fetch("ROLLBAR_ACCESS_TOKEN")
  end
end
