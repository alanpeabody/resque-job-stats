module Resque
  module Plugins
    module JobStats
      module MemoryUsage

        # Resets all job memory_usages
        def reset_job_memory_usages
          Resque.redis.del(jobs_memory_usages_key)
        end

        # Returns the number of jobs failed
        def job_memory_usages
          Resque.redis.lrange(jobs_memory_usage_key,0,memory_usages_recorded - 1).map(&:to_f)
        end

        # Returns the key used for tracking job memory_usages
        def jobs_memory_usage_key
          "stats:jobs:#{self.name}:memory_usage"
        end

        # Increments the failed count when job is complete
        def around_perform_job_stats_memory_usage(*args)
          # Lets zero out stats by triggering full GC sweep that will
          # elimitate any benefit of copy-on-write forking strategy
          GC.start
          # start will usually be equal to amount of memory Rails uses
          # on startup
          start = NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
          yield
          finish = NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
          memory_usage = finish - start

          Resque.redis.lpush(jobs_memory_usage_key, memory_usage)
          Resque.redis.ltrim(jobs_memory_usage_key, 0, memory_usages_recorded)
        end

        def memory_usages_recorded
          @memory_usages_recorded || 100
        end

        def job_memory_usage_rolling_avg
          job_times = job_memory_usages
          return 0.0 if job_times.size == 0.0
          job_times.inject(0.0) {|s,j| s + j} / job_times.size
        end

        def job_memory_usage_max
          job_memory_usages.max.to_f
        end
      end
    end
  end
end
