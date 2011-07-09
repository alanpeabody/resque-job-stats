require 'helper'

class SimpleJob
  extend Resque::Plugins::JobStats

  @queue = :test

  def perform(sleep_time=0.01)
    sleep sleep_time
  end
end

class TestResqueJobStats < MiniTest::Unit::TestCase
  def setup
    @worker = Resque::Worker.new(:test)
  end

  def test_jobs_performed

    SimpleJob.jobs_performed = 0
    
    3.times do
      Resque.enqueue(SimpleJob)
      @worker.work(0)
    end

    assert_equal SimpleJob.jobs_performed, 3

  end
end
