module Resque
  module Plugins
    module JobStats

      module EnqueuedAt
        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method :original_push, :push
            alias_method :original_pop, :pop
            extend ClassMethods
          end
        end

        module ClassMethods
          # wrapper for the original resque push method, which adds an
          # enqueued_at timestamp to any +item+ pushed onto the queue which
          # includes an args hash
          #
          def push(queue, item)
            if item.respond_to?(:[]=)
              item[:enqueued_at] = Time.now.utc
            end
            original_push queue, item
          end

          def pop(queue)
            item = original_pop(queue)
            if item.respond_to?(:[]=) && enqueued_at = item["enqueued_at"]
              wait_time = Time.now.utc - Time.parse(enqueued_at)

              item_class = constantize(item['class'])

              if queue_wait_class?(item_class)
                Resque.redis.lpush(item_class.jobs_wait_key, wait_time)
                Resque.redis.ltrim(item_class.jobs_wait_key, 0, item_class.wait_times_recorded)
              end
            end
            item
          end

          private

          def queue_wait_class?(item_class)
            item_class && item_class.respond_to?(:jobs_wait_key) && item_class.respond_to?(:wait_times_recorded)
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
