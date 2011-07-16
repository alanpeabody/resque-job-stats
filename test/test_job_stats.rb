require 'helper'

class BaseJob
  @queue = :test

  def self.perform(sleep_time=0.01)
    sleep sleep_time
  end
end

class SimpleJob < BaseJob
  extend Resque::Plugins::JobStats
  @queue = :test
end

class FailJob < BaseJob
  extend Resque::Plugins::JobStats::Failed
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
    Resque::Plugin.lint(Resque::Plugins::JobStats)
    assert_equal true, true
  rescue => e
    assert_equal false, e
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

  def test_duration
    assert_equal 'stats:jobs:SimpleJob:duration', SimpleJob.jobs_duration_key
    SimpleJob.reset_job_durations
    assert_equal 0.0, SimpleJob.job_rolling_avg
    3.times do |i|
      d = (i + 1)/10.0
      Resque.enqueue(SimpleJob,d)
      @worker.work(0)
    end
    assert_in_delta 0.3, SimpleJob.job_durations[0], 0.01
    assert_in_delta 0.2, SimpleJob.job_durations[1], 0.01
    assert_in_delta 0.1, SimpleJob.job_durations[2], 0.01
    assert_in_delta 0.3, SimpleJob.longest_job, 0.01
    assert_in_delta 0.2, SimpleJob.job_rolling_avg, 0.01
  end

end
