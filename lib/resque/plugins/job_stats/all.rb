require 'resque/plugins/job_stats/performed'
require 'resque/plugins/job_stats/enqueued'
require 'resque/plugins/job_stats/failed'
require 'resque/plugins/job_stats/duration'
require 'resque/plugins/job_stats/memory_usage'
require 'resque/plugins/job_stats/timeseries'

module Resque
  module Plugins
    module JobStats
      module All
        include Resque::Plugins::JobStats::Performed
        include Resque::Plugins::JobStats::Enqueued
        include Resque::Plugins::JobStats::Failed
        include Resque::Plugins::JobStats::Duration
        include Resque::Plugins::JobStats::MemoryUsage
        include Resque::Plugins::JobStats::Timeseries::Enqueued
        include Resque::Plugins::JobStats::Timeseries::Performed
      end
    end
  end
end
