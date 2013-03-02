require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require 'resque-job-stats/server'

# A pretend job that has all of the statistics we want to display (i.e. extends 
# Resque::Plugins::JobStats)
class AnyJobber
  class << self
    def jobs_enqueued
      111
    end

    def jobs_performed
      12345
    end

    def jobs_failed
      0
    end

    def job_rolling_avg
      0.3333232
    end

    def longest_job
      0.455555
    end

    def queued_per_minute
      {"2013-03-01 01:16:00 UTC"=>222, "2013-03-01 01:15:00 UTC"=>0}
    end

    def queued_per_hour
      {"2013-03-01 01:17:00 UTC"=>333, "2013-03-01 00:18:00 UTC"=>0}
    end

    def performed_per_minute
      {"2013-03-01 01:16:00 UTC"=>444, "2013-03-01 01:15:00 UTC"=>0}
    end

    def performed_per_hour
      {"2013-03-01 01:17:00 UTC"=>555, "2013-03-01 01:18:00 UTC"=>0}
    end

    def pending_per_minute
      {"2013-03-01 01:16:00 UTC"=>666, "2013-03-01 01:15:00 UTC"=>0}
    end

    def pending_per_hour
      {"2013-03-01 01:17:00 UTC"=>777, "2013-03-01 01:18:00 UTC"=>0}
    end
  end
end

class YetAnotherJobber < AnyJobber
end

class MyServer
  def self.job_stats_to_display
    [:jobs_enqueued]
  end

  include Resque::Plugins::JobStats::Server::Helpers
end

ENV['RACK_ENV'] = 'test'
class TestServer < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def setup
    Resque::Server.job_stats_to_display = Resque::Plugins::JobStats::Statistic::DEFAULT_STATS 
    @server = MyServer.new
  end

  def app
    Resque::Server
  end

  def test_job_stats
    Resque::Plugins::JobStats.stub :measured_jobs, [AnyJobber] do
      get '/job_stats'
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("<td>AnyJobber</td>"), "job name was not found"
      assert last_response.body.include?("<td>111</td>"), "jobs_enqueued was not found"
      assert last_response.body.include?("<td>12345</td>"), "jobs_performed was not found"
      assert last_response.body.include?("<td></td>"), "jobs_failed was not found"
      assert last_response.body.include?("<td>0.33s</td>"),  "job_rolling_avg was not found"
      assert last_response.body.include?("<td>0.46s</td>"), "longest_job was not found"
    end
  end

  def test_job_stats_filtered
    Resque::Server.job_stats_to_display = [:longest_job]
    Resque::Plugins::JobStats.stub :measured_jobs, [AnyJobber] do
      get '/job_stats'
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("<td>AnyJobber</td>"), "job name was not found"
      assert !last_response.body.include?("<td>111</td>"), "jobs_enqueued was not found"
      assert !last_response.body.include?("<td>12345</td>"), "jobs_performed was not found"
      assert !last_response.body.include?("<td></td>"), "jobs_failed was not found"
      assert !last_response.body.include?("<td>0.33s</td>"),  "job_rolling_avg was not found"
      assert last_response.body.include?("<td>0.46s</td>"), "longest_job was not found"
    end
  end

  def test_job_stats_timeseries_minute
    Resque::Plugins::JobStats.stub :measured_jobs, [AnyJobber] do
      get '/job_stats_timeseries_minute'
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("AnyJobber"), "job name was not found"
      assert last_response.body.include?("<td>2013-03-01 01:16:00 UTC</td>"),  "queued_per_minute was not found"
      assert last_response.body.include?("<td>222</td>"),  "queued_per_minute value was not found"
      assert last_response.body.include?("<td>444</td>"),  "performed_per_minute value was not found"
      assert last_response.body.include?("<td>3.0</td>"),  "pending_per_minute average value was not found"
    end
  end

  def test_job_stats_timeseries_minute_filtered
    Resque::Server.job_stats_to_display = [:queued_per_minute, :pending_per_minute]
    Resque::Plugins::JobStats.stub :measured_jobs, [AnyJobber] do
      get '/job_stats_timeseries_minute'
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("AnyJobber"), "job name was not found"
      assert last_response.body.include?("<td>2013-03-01 01:16:00 UTC</td>"),  "queued_per_minute was not found"
      assert last_response.body.include?("<td>222</td>"),  "queued_per_minute value was not found"
      assert !last_response.body.include?("<td>444</td>"),  "performed_per_minute value was not found"
      assert last_response.body.include?("<td>3.0</td>"),  "pending_per_minute average value was not found"
    end
  end

  def test_job_stats_timeseries_hour
    Resque::Plugins::JobStats.stub :measured_jobs, [AnyJobber] do
      get '/job_stats_timeseries_hour'
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("AnyJobber"), "job name was not found"
      assert last_response.body.include?("<td>2013-03-01 01:17:00 UTC</td>"),  "queued_per_hour was not found"
      assert last_response.body.include?("<td>333</td>"),  "queued_per_hour value was not found"
      assert last_response.body.include?("<td>555</td>"),  "performed_per_hour value was not found"
      assert last_response.body.include?("<td>2.33</td>"),  "pending_per_hour average value was not found"
    end
  end

  def test_job_stats_timeseries_hour_filtered
    Resque::Server.job_stats_to_display = [:queued_per_hour]
    Resque::Plugins::JobStats.stub :measured_jobs, [AnyJobber] do
      get '/job_stats_timeseries_hour'
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("AnyJobber"), "job name was not found"
      assert last_response.body.include?("<td>2013-03-01 01:17:00 UTC</td>"),  "queued_per_hour was not found"
      assert last_response.body.include?("<td>333</td>"),  "queued_per_hour value was not found"
      assert !last_response.body.include?("<td>555</td>"),  "performed_per_hour value was not found"
      assert !last_response.body.include?("<td>2.33</td>"),  "pending_per_hour average value was not found"
    end
  end

  def test_job_stats_timeseries_hour_filtered_performed
    Resque::Server.job_stats_to_display = [:performed_per_hour]
    Resque::Plugins::JobStats.stub :measured_jobs, [AnyJobber] do
      get '/job_stats_timeseries_hour'
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("AnyJobber"), "job name was not found"
      assert last_response.body.include?("<td>2013-03-01 01:17:00 UTC</td>"),  "performed_per_hour time was not found"
      assert !last_response.body.include?("<td>333</td>"),  "queued_per_hour value was not found"
      assert last_response.body.include?("<td>555</td>"),  "performed_per_hour value was not found"
      assert !last_response.body.include?("<td>2.33</td>"),  "pending_per_hour average value was not found"
    end
  end

  def test_stat_header
    assert_equal "<th>Jobs enqueued</th>", @server.stat_header(:jobs_enqueued)
    assert_equal nil, @server.stat_header(:FOOOOOOO)
  end

  def test_display_stat?
    assert !@server.display_stat?(:jobs_barfing)
    assert @server.display_stat?(:jobs_enqueued)
  end

  def test_job_sorting
    Resque::Plugins::JobStats.stub :measured_jobs, [YetAnotherJobber, AnyJobber] do
      get '/job_stats'
      assert_equal 200, last_response.status, last_response.body
      assert(last_response.body =~ /AnyJobber(.|\n)+YetAnotherJobber/, "AnyJobber should be found before YetAnotherJobber")
    end
  end

  def test_tabs
    assert app.tabs.include?("Job_Stats"), "The tab should be in resque's server"
  end
end
