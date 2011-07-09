require 'resque'
require 'resque/plugins/job_stats/performed'
require 'resque/plugins/job_stats/failed'
require 'resque/plugins/job_stats/duration'

module Resque
  module Plugins
    module JobStats
      include Resque::Plugins::JobStats::Performed
      include Resque::Plugins::JobStats::Failed
      include Resque::Plugins::JobStats::Duration
    end
  end
end
