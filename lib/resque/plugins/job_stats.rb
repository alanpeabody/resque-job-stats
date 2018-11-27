require 'resque'
require 'resque/plugins/job_stats/performed'
require 'resque/plugins/job_stats/enqueued'
require 'resque/plugins/job_stats/failed'
require 'resque/plugins/job_stats/duration'
require 'resque/plugins/job_stats/timeseries'
require 'resque/plugins/job_stats/statistic'
require 'resque/plugins/job_stats/history'

module Resque
  module Plugins
    module JobStats
      include Resque::Plugins::JobStats::Performed
      include Resque::Plugins::JobStats::Enqueued
      include Resque::Plugins::JobStats::Failed
      include Resque::Plugins::JobStats::Duration
      include Resque::Plugins::JobStats::Timeseries::Enqueued
      include Resque::Plugins::JobStats::Timeseries::Performed
      include Resque::Plugins::JobStats::History
      
      def self.extended(base)
        Resque.redis.sadd("stats:jobs", base.to_s)
      end

      def self.add_measured_job(name)
        Resque.redis.sadd("stats:jobs", name)
      end

      def self.rem_measured_job(name)
        Resque.redis.srem("stats:jobs", name)
      end

      def self.measured_jobs
        Resque.redis.smembers("stats:jobs").collect { |c| c rescue nil }.compact
      end
    end
  end
end
