require 'resque'
require 'resque/plugins/job_stats/performed'

module Resque
  module Plugins
    module JobStats
      include Resque::Plugins::JobStats::Performed
    end
  end
end
