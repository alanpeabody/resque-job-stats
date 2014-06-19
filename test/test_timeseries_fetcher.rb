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

class TestTimeseriesFetcher < MiniTest::Unit::TestCase
  def setup
    # Ensure empty redis for each test
    Resque.redis.flushdb
    @worker = Resque::Worker.new(:test)
  end

  def test_enqueue_timeseries
    time = SimpleJob.timestamp
    Timecop.freeze(time)
    Resque.enqueue(SimpleJob,0)
    Timecop.freeze(time + 60)
    @worker.work(0)

    queued_per_minute = Resque::Plugins::JobStats::TimeseriesFetcher.queued_per_minute('SimpleJob')
    performed_per_minute = Resque::Plugins::JobStats::TimeseriesFetcher.performed_per_minute('SimpleJob')
    assert_equal 1, queued_per_minute[time]
    assert_equal 0, queued_per_minute[(time + 60)]
    assert_equal 1, performed_per_minute[(time + 60)]

    Timecop.return
  end
end
