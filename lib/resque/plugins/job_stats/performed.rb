module Resque
  module Plugins
    module JobStats

      # Extend your job with this module to track how many
      # jobs are performed successfully
      module Performed
        include Resque::Plugins::JobStats::MeasuredHook

        # Sets the number of jobs performed
        def jobs_performed=(int)
          Resque.redis.set(jobs_performed_key,int)
        end

        # Returns the number of jobs performed
        def jobs_performed
          Resque.redis.get(jobs_performed_key).to_i
        end

        # Returns the key used for tracking jobs performed
        def jobs_performed_key
          "stats:jobs:#{self.name}:performed"
        end

        # Increments the performed count when job is complete
        def after_perform_job_stats_performed(*args)
          Resque.redis.incr(jobs_performed_key)
        end

      end
    end
  end
end
