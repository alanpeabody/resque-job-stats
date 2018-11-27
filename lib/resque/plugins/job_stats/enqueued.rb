module Resque
  module Plugins
    module JobStats

      # Extend your job with this module to track how many
      # jobs are queued successfully
      module Enqueued

        # Sets the number of jobs queued
        def jobs_enqueued=(int)
          Resque.redis.set(jobs_enqueued_key,int)
        end

        # Returns the number of jobs enqueued
        def jobs_enqueued
          Resque.redis.get(jobs_enqueued_key).to_i
        end

        # Returns the key used for tracking jobs enqueued
        def jobs_enqueued_key
          "stats:jobs:#{self.name}:enqueued"
        end

        # Increments the enqueued count when job is queued
        def after_enqueue_job_stats_enqueued(*args)
          Resque.redis.incr(jobs_enqueued_key)
        end

      end
    end
  end
end

