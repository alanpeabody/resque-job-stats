module Resque
  module Plugins
    module JobStats
      # Extend your job with this module to track how long
      # jobs are waiting in the queue before being processed
      module QueueWait

        # Resets all job wait times
        def reset_job_wait_times
          Resque.redis.del(jobs_wait_key)
        end

        # Returns the recorded wait times
        def job_wait_times
          Resque.redis.lrange(jobs_wait_key,0,wait_times_recorded - 1).map(&:to_f)
        end

        # Returns the key used for tracking job wait times
        def jobs_wait_key
          "stats:jobs:#{self.name}:waittime"
        end

        def message_enqueued_key(args)
          "stats:jobs:#{self.name}:message-enqueued-at:#{args.to_s.hash}"
        end

        def after_enqueue_job_stats_queue_wait(*args)
          Resque.redis.lpush(message_enqueued_key(args), Time.now.utc.to_i)
        end

        def before_perform_job_stats_queue_wait(*args)
          if enqueued_at = Resque.redis.rpop(message_enqueued_key(args))
            wait_time = Time.now.utc.to_i - enqueued_at.to_i
            Resque.redis.lpush(jobs_wait_key, wait_time)
            Resque.redis.ltrim(jobs_wait_key, 0, wait_times_recorded)
          end
        end

        def wait_times_recorded
          @wait_times_recorded || 100
        end

        def rolling_avg_wait_time
          wait_times = job_wait_times
          return 0.0 if wait_times.size == 0.0
          wait_times.inject(0.0) {|s,j| s + j} / wait_times.size
        end

        def longest_wait
          job_wait_times.max.to_f
        end

      end
    end
  end
end
