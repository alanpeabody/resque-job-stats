require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/unit'
require 'redgreen'
require 'resque'
require 'timecop'

#
# make sure we can run redis
#
if !system("which redis-server")
  puts '', "** can't find `redis-server` in your path"
  puts "** add redis-server to your PATH and try again"
  abort ''
end

#
# start our own redis when the tests start,
# kill it when they end
#
dir = File.dirname(__FILE__)
at_exit do
  pid = `ps -e -o pid,command | grep [r]edis-test`.split(" ")[0]
  puts "Killing test redis server [#{pid}]..."
  `rm -f #{dir}/dump.rdb`
  Process.kill("KILL", pid.to_i)
end

puts "Starting redis for testing at localhost:9736..."
`redis-server #{dir}/redis-test.conf`
Resque.redis = 'localhost:9736'
Resque.redis.namespace = 'resque:job_stats'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'resque-job-stats'



class MiniTest::Unit::TestCase
end

MiniTest::Unit.autorun
