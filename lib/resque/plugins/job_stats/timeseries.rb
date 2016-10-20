require 'time'

module Resque
  module Plugins
    module JobStats

      # Extend your job with this module to track how many
      # jobs are performed over a period of time
      module Timeseries

        module Common
          # A timestamp rounded to the lowest minute
          def timestamp
            time = Time.now.utc
            Time.at(time.to_i - time.sec).utc   # to_i removes usecs
          end

          private

          TIME_FORMAT = {:minutes => "%d:%H:%M", :hours => "%d:%H"}
          FACTOR = {:minutes => 1, :hours => 60}

          def range(sample_size, time_unit, end_time) # :nodoc:
            (0..sample_size).map { |n| end_time - (n * 60 * FACTOR[time_unit])}
          end

          def timeseries_data(type, sample_size, time_unit) # :nodoc:
            timeseries_range = range(sample_size, time_unit, timestamp)
            timeseries_keys = timeseries_range.map { |time| jobs_timeseries_key(type, time, time_unit)}
            timeseries_data = Resque.redis.mget(*(timeseries_keys))

            return Hash[(0..sample_size).map { |i| [timeseries_range[i], timeseries_data[i].to_i]}]
          end

          def jobs_timeseries_key(type, key_time, time_unit) # :nodoc:
            "#{prefix}:#{type}:#{key_time.strftime(TIME_FORMAT[time_unit])}"
          end

          def prefix # :nodoc:
            "stats:jobs:#{self.name}:timeseries"
          end

          def incr_timeseries(type, value=1) # :nodoc:
            increx(jobs_timeseries_key(type, timestamp, :minutes), (60 * 61), value) # 1h + 1m for some buffer
            increx(jobs_timeseries_key(type, timestamp, :hours), (60 * 60 * 25), value) # 24h + 60m for some buffer
          end

          # Increments a key and sets its expiry time
          def increx(key, ttl, value)
            Resque.redis.incrby(key, value)
            Resque.redis.expire(key, ttl)
          end
        end
      end
    end
  end
end

module Resque::Plugins::JobStats::Timeseries::Enqueued
  include Resque::Plugins::JobStats::Timeseries::Common

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

module Resque::Plugins::JobStats::Timeseries::Performed
  include Resque::Plugins::JobStats::Timeseries::Common

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

module Resque::Plugins::JobStats::Timeseries::Pending
  include Resque::Plugins::JobStats::Timeseries::Common

  # Increments the pending count for the timestamp when job is complete
  def after_enqueue_job_stats_timeseries_pending(*args)
    incr_timeseries(:pending, Resque.info[:pending])
  end

  # Hash of timeseries data over the last 60 minutes for pending jobs 
  def pending_per_minute 
    timeseries_data(:pending, 60, :minutes)
  end

  # Hash of timeseries data over the last 24 hours for pending jobs
  def pending_per_hour 
    timeseries_data(:pending, 24, :hours)
  end
end
