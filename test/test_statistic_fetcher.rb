require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

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

class TestStatisticFetcher < MiniTest::Unit::TestCase
  def setup
    # Ensure empty redis for each test
    Resque.redis.flushdb
    @worker = Resque::Worker.new(:test)

  end

  def test_enqueued
    time = SimpleJob.timestamp
    Timecop.freeze(time)
    Resque.enqueue(SimpleJob,0)
    Timecop.freeze(time + 60)
    @worker.work(0)
    Timecop.return
    @statistic_fetcher = Resque::Plugins::JobStats::StatisticFetcher.new "SimpleJob"
    assert_equal 1, @statistic_fetcher.jobs_enqueued
  end

  def test_performed
    time = SimpleJob.timestamp
    Timecop.freeze(time)
    Resque.enqueue(SimpleJob,0)
    Timecop.freeze(time + 60)
    @worker.work(0)
    Timecop.return
    @statistic_fetcher = Resque::Plugins::JobStats::StatisticFetcher.new "SimpleJob"
    assert_equal 1, @statistic_fetcher.jobs_performed
  end

  def test_failed
    Resque.enqueue(FailJob, 0)
    @worker.work(0)
    @statistic_fetcher = Resque::Plugins::JobStats::StatisticFetcher.new "FailJob"
    assert_equal 1, @statistic_fetcher.jobs_failed
  end

  def test_enqueue_timeseries
    time = SimpleJob.timestamp
    Timecop.freeze(time)
    Resque.enqueue(SimpleJob,0)
    Timecop.freeze(time + 60)
    @worker.work(0)

    @statistic_fetcher = Resque::Plugins::JobStats::StatisticFetcher.new "SimpleJob"

    queued_per_minute = @statistic_fetcher.queued_per_minute()
    performed_per_minute = @statistic_fetcher.performed_per_minute()
    assert_equal 1, queued_per_minute[time]
    assert_equal 0, queued_per_minute[(time + 60)]
    assert_equal 1, performed_per_minute[(time + 60)]

    Timecop.return
  end
end
