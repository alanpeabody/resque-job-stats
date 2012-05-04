module Resque
  module Plugins
    module JobStats

      module EnqueuedAt
        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method :push_without_timestamp, :push
            extend ClassMethods
          end
        end

        module ClassMethods
          # wrapper for the original resque push method, which adds an
          # enqueued_at timestamp to any +item+ pushed onto the queue which
          # includes an args hash
          #
          def push(queue, item)
            if item.include?(:args)
              item[:args] << {:enqueued_at => Time.now.utc}
            end
            push_without_timestamp queue, item
          end
        end
      end

      # Extend your job with this module to track how long
      # jobs are wating in the queue before being processed
      module QueueWait

        def self.extended(base) #:nodoc:
          Resque.send(:include, Resque::Plugins::JobStats::EnqueuedAt)
        end

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

        # Records the job wait time
        def before_perform_job_stats_queue_wait(*args)
          time = Time.now.utc
          enqueued_at = time
          args.each { |arg| enqueued_at = Time.parse(arg["enqueued_at"]) if arg.is_a?(::Hash) && !arg["enqueued_at"].nil?}

          wait_time = time - enqueued_at

          Resque.redis.lpush(jobs_wait_key, wait_time)
          Resque.redis.ltrim(jobs_wait_key, 0, wait_times_recorded)
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
