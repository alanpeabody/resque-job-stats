require 'resque'
require 'resque/plugins/job_stats/performed'
require 'resque/plugins/job_stats/failed'

module Resque
  module Plugins
    module JobStats
      include Resque::Plugins::JobStats::Performed
      include Resque::Plugins::JobStats::Failed
    end
  end
end
