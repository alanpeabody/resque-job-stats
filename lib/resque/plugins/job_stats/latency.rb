module Resque
  module Plugins
    module JobStats
      module Latency
        
        # Resets all job latencys
        def reset_job_latencys
          Resque.redis.del(jobs_latency_key)
        end

        # Returns the number of jobs failed
        def job_latencys
          Resque.redis.lrange(jobs_latency_key,0,latencys_recorded - 1).map(&:to_f)
        end

        # Returns the key used for tracking job latencys
        def jobs_latency_key
          "stats:jobs:#{self.name}:latency"
        end

        # Increments the failed count when job is complete
        def after_perform_job_stats_latency(*args)
          if self.enqueued_at && self.performed_at
            latency = self.performed_at - self.enqueued_at
            Resque::Plugins::JobStats.add_measured_job(self.name)
            Resque.redis.lpush(jobs_latency_key, latency)
            Resque.redis.ltrim(jobs_latency_key, 0, latencys_recorded)
          end
        end

        def latencys_recorded
          @latencys_recorded || 100
        end

        def job_latency_avg
          job_times = job_latencys
          return 0.0 if job_times.size == 0.0
          job_times.inject(0.0) {|s,j| s + j} / job_times.size
        end

        def job_latency_max
          job_latencys.max.to_f
        end

      end
    end
  end
end