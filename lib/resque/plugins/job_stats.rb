# loaded by resque-web 'automagically' to initialize plugin UI

require 'resque'
require 'resque/plugins/job_stats/all'
require 'resque/plugins/job_stats/statistic'

module Resque
  module Plugins
    module JobStats
      include Resque::Plugins::JobStats::All
    end
  end
end
