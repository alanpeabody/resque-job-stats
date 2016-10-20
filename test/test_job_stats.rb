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

  def self.perform(*args)
    raise 'fail'
  end
end

class CustomDurJob < BaseJob
  extend Resque::Plugins::JobStats::Duration
  @queue = :test
  @durations_recorded = 5
end

class TestResqueJobStats < MiniTest::Unit::TestCase

  def setup
    # Ensure empty redis for each test
    Resque.redis.flushdb
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

  def test_jobs_enqueued
    assert_equal 'stats:jobs:SimpleJob:enqueued', SimpleJob.jobs_enqueued_key
    SimpleJob.jobs_enqueued = 0
    3.times do
      Resque.enqueue(SimpleJob)
      @worker.work(0)
    end
    assert_equal 3, SimpleJob.jobs_enqueued
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
    assert_equal 0.0, SimpleJob.longest_job

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

  def test_custom_duration
    CustomDurJob.reset_job_durations

    2.times do
      Resque.enqueue(CustomDurJob,1.0)
      @worker.work(0)
    end

    5.times do
      Resque.enqueue(CustomDurJob,0.1)
      @worker.work(0)
    end

    assert_in_delta 0.1, CustomDurJob.longest_job, 0.01
    assert_in_delta 0.1, CustomDurJob.job_rolling_avg, 0.01
  end

  def test_perform_timeseries
    time = SimpleJob.timestamp
    3.times do
      Resque.enqueue(SimpleJob)
      @worker.work(0)
    end
    assert_equal 3, SimpleJob.performed_per_minute[time]
    assert_equal 0, SimpleJob.performed_per_minute[(time - 60)]

    assert_equal 3, SimpleJob.performed_per_hour[time]
    assert_equal 0, SimpleJob.performed_per_hour[(time - 3600)]
  end

  def test_enqueue_timeseries
    time = SimpleJob.timestamp
    Timecop.freeze(time)
    Resque.enqueue(SimpleJob,0)
    Timecop.freeze(time + 60)
    @worker.work(0)
    assert_equal 1, SimpleJob.queued_per_minute[time]
    assert_equal 0, SimpleJob.queued_per_minute[(time + 60)]
    assert_equal 1, SimpleJob.performed_per_minute[(time + 60)]
    Timecop.return
  end

  def test_queue_pending
    time = SimpleJob.timestamp
    3.times do
      Resque.enqueue(SimpleJob)
    end

    assert_equal 6, SimpleJob.pending_per_minute[time]
    assert_equal 6, SimpleJob.pending_per_hour[time]
  end

  def test_measured_jobs
    assert_equal [SimpleJob], Resque::Plugins::JobStats.measured_jobs
  end
end
