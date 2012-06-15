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