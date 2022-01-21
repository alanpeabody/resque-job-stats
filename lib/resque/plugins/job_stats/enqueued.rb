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

        def number_of_jobs_in_queue
          Resque.size(self.queue)
        end

        def been_in_the_queue_for(enqueued_since)
          time_diff(Time.now, enqueued_since)
        end

        private
        def time_diff(start_time, end_time)
          seconds_diff = (start_time - end_time).to_i.abs

          hours = seconds_diff / 3600
          seconds_diff -= hours * 3600

          minutes = seconds_diff / 60
          seconds_diff -= minutes * 60

          seconds = seconds_diff

          "#{hours.to_s.rjust(2, '0')}:#{minutes.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}"
        end
      end
    end
  end
end

