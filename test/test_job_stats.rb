require 'helper'

class SimpleJob
  extend Resque::Plugins::JobStats

  @queue = :test

  def self.perform(sleep_time=0.01)
    sleep sleep_time
  end
end

class FailJob
  extend Resque::Plugins::JobStats

  @queue = :test

  def self.perform(*payload)
    raise 'fail'
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

  def test_jobs_failed

    assert_equal 'stats:jobs:FailJob:failed', FailJob.jobs_failed_key

    FailJob.jobs_failed = 0
    
    3.times do
      Resque.enqueue(FailJob)
      @worker.work(0)
    end

    assert_equal 3, FailJob.jobs_failed

  end
end
