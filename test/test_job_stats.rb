require 'helper'

class SimpleJob
  extend Resque::Plugins::JobStats

  @queue = :test

  def self.perform(sleep_time=0.01)
    sleep sleep_time
  end
end

class TestResqueJobStats < MiniTest::Unit::TestCase
  def setup
    @worker = Resque::Worker.new(:test)
  end

  def test_lint
    skip('Figure out exceptions')
    Resque::Plugin.lint(Resque::Plugins::JobStats)
  end

  def test_jobs_performed

    assert_equal 'stats:jobs:SimpleJob:performed', SimpleJob.jobs_performed_key

    SimpleJob.jobs_performed = 0
    
    3.times do
      Resque.enqueue(SimpleJob)
      @worker.work(0)
    end

    assert_equal 3, SimpleJob.jobs_performed

  end
end
