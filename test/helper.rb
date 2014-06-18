require 'rubygems'
require 'bundler'
require "minitest/autorun"
require 'bundler/setup'


begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/unit'
require 'minitest/mock'
require "mocha/mini_test"
require 'rack/test'
require 'redgreen'
require 'resque'
require 'timecop'

Resque.redis = 'localhost:6379'
Resque.redis.namespace = 'resque:job_stats'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'resque-job-stats'



class MiniTest::Unit::TestCase
end

MiniTest::Unit.autorun
