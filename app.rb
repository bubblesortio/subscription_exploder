require "sinatra"
require "sinatra/activerecord"
require_relative "./bubblesort"

configure do
  db = URI.parse(ENV['DATABASE_URL'] || 'postgres:///subscription_exploder')

  ActiveRecord::Base.establish_connection(
    :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    :host     => db.host,
    :port     => db.port,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
end

configure :development do
  set :show_exceptions, true
end

