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
        self.measured_jobs << base
      end

      def self.measured_jobs
        @measured_jobs ||= []
      end
    end
  end
end
