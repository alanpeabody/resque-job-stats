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

# mocked job with history
class HistoricJob
  include Resque::Plugins::JobStats::History

  def self.job_histories(start=0,limit=2)
    [{"run_at" => "Thu Jan 02 03:45:01 -0700 2012",
      "duration" => 1.2345,
      "args" => [1, 2, "3"],
      "success" => true},
     {"run_at" => "Thu Jan 02 03:45:01 -0700 2011",
      "duration" => 6.7890,
      "args" => ["a", "b"],
      "success" => false,
      "exception" => {"name" => "bad stuff", "backtrace" => ["a", "b"]}}][start,limit]
  end

  def self.histories_recorded
    2
  end

  def self.jobs_performed
    1
  end
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
      assert last_response.body =~ /<td>\s*AnyJobber\s*<\/td>/, "job name was not found"
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
      assert last_response.body =~ /<td>\s*AnyJobber\s*<\/td>/, "job name was not found"
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

  def test_job_stats_history_link
    Resque::Server.job_stats_to_display = [:jobs_performed]
    Resque::Plugins::JobStats.stub :measured_jobs, [HistoricJob,AnyJobber] do
      get "/job_stats"
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("<a href='http://example.org/job_history/HistoricJob'>[history]</a>"), "history link not found"
      assert !last_response.body.include?("<a href='http://example.org/job_history/AnyJobber'>[history]</a>"), "unexpected history link"
    end
  end

  def test_history
    Resque::Plugins::JobStats.stub :measured_jobs, [HistoricJob] do
      get "/job_history/HistoricJob"
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("<h2>HistoricJob</h2>"), "job name was not found"
      assert last_response.body.include?("<td><span class=\"time\">Thu Jan 02 03:45:01 -0700 2012</span></td>"), "start time not found"
      assert last_response.body.include?("<td>[1, 2, \"3\"]</td>"), "args not found"
      assert last_response.body.include?("<td>&#x2713;</td>"), "success marker not found"
    end
  end

  def test_history_pagination
    Resque::Plugins::JobStats.stub :measured_jobs, [HistoricJob] do
      get "/job_history/HistoricJob?start=1"
      assert_equal 200, last_response.status, last_response.body
      assert !last_response.body.include?("<td>&#x2713;</td>"), "success marker unexpected"
      assert last_response.body.include?("<td>&#x2717;</td>"), "failure marker not found"
      assert last_response.body.include?("<p class='pagination'>"), "pagination links not found"

      get "/job_history/HistoricJob?limit=1"
      assert_equal 200, last_response.status, last_response.body
      assert last_response.body.include?("<td>&#x2713;</td>"), "success marker not found"
      assert !last_response.body.include?("<td>&#x2717;</td>"), "failure marker unexpected"
      assert last_response.body.include?("<p class='pagination'>"), "pagination links not found"
    end
  end

  def test_no_history
    Resque::Plugins::JobStats.stub :measured_jobs, [AnyJobber] do
      get "/job_history/HistoricJob"
      assert_equal 404, last_response.status, last_response.body
    end
  end
end
