require 'time'

module Resque
  module Plugins
    module JobStats

      # Extend your job with this module to track how many
      # jobs are performed over a period of time
      module Timeseries

        module Enqueued
          include Resque::Plugins::JobStats::Timeseries

          # Increments the enqueued count for the timestamp when job is queued
          def after_enqueue_job_stats_timeseries(*args)
            incr_timeseries(:enqueued)
          end

          # Hash of timeseries data over the last 60 minutes for queued jobs
          def queued_per_minute
            timeseries_data(:enqueued, 60, :minutes)
          end

          # Hash of timeseries data over the last 24 hours for queued jobs
          def queued_per_hour
            timeseries_data(:enqueued, 24, :hours)
          end
        end

        module Performed
          include Resque::Plugins::JobStats::Timeseries

          # Increments the performed count for the timestamp when job is complete
          def after_perform_job_stats_timeseries(*args)
            incr_timeseries(:performed)
          end

          # Hash of timeseries data over the last 60 minutes for completed jobs
          def performed_per_minute
            timeseries_data(:performed, 60, :minutes)
          end

          # Hash of timeseries data over the last 24 hours for completed jobs
          def performed_per_hour
            timeseries_data(:performed, 24, :hours)
          end
        end

        private

          def timestamp # :nodoc:
            Time.now.utc
          end

          def period(sample_size, time_unit, from) # :nodoc:
            case time_unit
            when :minutes
              factor = 1
            when :hours
              factor = 60
            end
            (0..sample_size).map { |n| from - (n * 60 * factor)}
          end

          def timeseries_data(type, sample_size, time_unit) # :nodoc:
            period = period(sample_size, time_unit, timestamp)
            timeseries_data = Resque.redis.mget(*(period.map { |time| jobs_timeseries_key(type, time, time_unit)}) )
            return Hash[(0..sample_size).map { |i| [period[i].strftime(format(time_unit)), timeseries_data[i].to_i]}]
          end

          def jobs_timeseries_key(type, key_time, time_unit) # :nodoc:
            "#{prefix}:#{type}:#{key_time.strftime(format(time_unit))}"
          end

          def prefix # :nodoc:
            "stats:jobs:#{self.name}:timeseries"
          end

          def format(unit) # :nodoc:
            case unit
            when :minutes
              "%d:%H:%M"
            when :hours
              "%d:%H"
            end
          end

          def incr_timeseries(type) # :nodoc:
            increx(jobs_timeseries_key(type, timestamp, :minutes), (60 * 61)) # 1h + 1m for some buffer
            increx(jobs_timeseries_key(type, timestamp, :hours), (60 * 60 * 25)) # 24h + 60m for some buffer
          end

          # Increments a key and sets its expiry time
          def increx(key, ttl)
            Resque.redis.incr(key)
            Resque.redis.expire(key, ttl)
          end

      end
    end
  end
end

