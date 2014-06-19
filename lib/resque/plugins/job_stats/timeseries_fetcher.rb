# Fetch timeseries data from Redis directly and not need to access
# the job classes
module Resque
  module Plugins
    module JobStats
      module TimeseriesFetcher
        extend Resque::Plugins::JobStats::Timeseries::Common

        def self.performed_per_minute(job_name)
          timeseries_data(:performed, 60, :minutes, job_name)
        end

        def self.performed_per_hour(job_name)
          timeseries_data(:performed, 24, :hours, job_name)
        end

        def self.performed_per_day(job_name)
          timeseries_data(:performed, 90, :days, job_name)
        end

        def self.queued_per_minute(job_name)
          timeseries_data(:enqueued, 60, :minutes, job_name)
        end

        def self.queued_per_hour(job_name)
          timeseries_data(:enqueued, 24, :hours, job_name)
        end

        def self.queued_per_day(job_name)
          timeseries_data(:enqueued, 90, :days, job_name)
        end
      end
    end
  end
end
