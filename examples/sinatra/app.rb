require './job'
require 'resque/server'
require 'resque-job-stats'
require 'resque-job-stats/server'

Resque.redis = Redis.new

class ExampleApp < Resque::Server
end
