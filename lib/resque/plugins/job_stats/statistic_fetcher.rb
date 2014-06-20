module Resque
  module Plugins
    module JobStats
      # This class fetch the time series from redis and doesn't need to load
      # job classes
      class StatisticFetcher

        # Get a StatisticFetcher for all jobs
        def self.statistic_fetcher_for_all_jobs
          job_names = Set.new
          Resque.keys.each do |key|
            /\Astats:jobs:(.*):timeseries:.+\z/.match(key)
            job_names << $1 if $1
          end
          job_names.to_a.sort.map { |job_name| StatisticFetcher.new(job_name)}
        end

        include Resque::Plugins::JobStats::Duration
        include Resque::Plugins::JobStats::Enqueued
        include Resque::Plugins::JobStats::Failed
        include Resque::Plugins::JobStats::Performed
        include Resque::Plugins::JobStats::Timeseries::Enqueued
        include Resque::Plugins::JobStats::Timeseries::Performed

        def initialize(job_name)
          @job_name = job_name
        end

        def name
          @job_name
        end
      end
    end
  end
end
