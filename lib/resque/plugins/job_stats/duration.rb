module Resque
  module Plugins
    module JobStats
      module Duration

        # Resets all job durations
        def reset_job_durations
          Resque.redis.del(jobs_duration_key)
        end

        # Returns the recorded durations
        def job_durations
          Resque.redis.lrange(jobs_duration_key,0,durations_recorded - 1).map(&:to_f)
        end

        # Returns the key used for tracking job durations
        def jobs_duration_key
          "stats:jobs:#{self.name}:duration"
        end

        # Records the job duration
        def around_perform_job_stats_duration(*args)
          start = Time.now
          yield
          duration = Time.now - start

          Resque.redis.lpush(jobs_duration_key, duration)
          Resque.redis.ltrim(jobs_duration_key, 0, durations_recorded)
        end

        def durations_recorded
          @durations_recorded || 100
        end

        def job_rolling_avg
          job_times = job_durations
          return 0.0 if job_times.size == 0.0
          job_times.inject(0.0) {|s,j| s + j} / job_times.size
        end

        def longest_job
          job_durations.max.to_f
        end

      end
    end
  end
end
