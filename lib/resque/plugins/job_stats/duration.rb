module Resque
  module Plugins
    module JobStats
      module Duration

        # Resets all job durations
        def reset_job_durations
          Resque.redis.del(jobs_duration_key(true))
          Resque.redis.del(jobs_duration_key(false))
        end

        # Returns the number of jobs failed
        def job_durations(success=true)
          Resque.redis.lrange(jobs_duration_key(success),0,durations_recorded - 1).map(&:to_f)
        end

        def failed_job_durations
          job_durations(false)
        end

        # Returns the key used for tracking job durations
        def jobs_duration_key(success=true)
          "stats:jobs:#{self.name}:#{success ? '' : 'failure:'}duration"
        end

        # Increments the failed count when job is complete
        def around_perform_job_stats_duration(*args)
          start = Time.now
          success = true
          yield
        rescue Exception
          success = false
          raise
        ensure
          duration = Time.now - start

          Resque.redis.lpush(jobs_duration_key(success), duration)
          Resque.redis.ltrim(jobs_duration_key(success), 0, durations_recorded)
        end

        def durations_recorded
          @durations_recorded || 100
        end

        def job_rolling_avg(success=true)
          job_times = job_durations(success)
          return 0.0 if job_times.size == 0.0
          job_times.inject(0.0) {|s,j| s + j} / job_times.size
        end

        def longest_job(success=true)
          job_durations(success).max.to_f
        end

        def failed_job_rolling_avg
          job_rolling_avg(false)
        end

        def longest_failed_job
          longest_job(false)
        end

      end
    end
  end
end
