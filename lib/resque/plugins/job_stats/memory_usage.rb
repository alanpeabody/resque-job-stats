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
          Resque.redis.lrange(jobs_memory_usage_key, 0, -1).map(&:to_f)
        end

        # Returns the key used for tracking job memory_usages
        def jobs_memory_usage_key
          "stats:jobs:#{self.name}:memory_usage"
        end

        # Increments the failed count when job is complete
        def around_perform_job_stats_memory_usage(*args)
          # start will usually be equal to amount of memory Rails uses
          # on startup
          start = collect_memory_usage
          yield
          finish = collect_memory_usage

          memory_usage = finish - start

          Resque.redis.lpush(jobs_memory_usage_key, memory_usage)
          Resque.redis.ltrim(jobs_memory_usage_key, 0, memory_usages_recorded - 1)
        end

        def memory_usages_recorded
          @memory_usages_recorded || 100
        end

        attr_writer :memory_usages_recorded

        def job_memory_usage_rolling_avg
          job_times = job_memory_usages
          return 0.0 if job_times.size == 0.0
          job_times.inject(0.0) {|s,j| s + j} / job_times.size
        end

        def job_memory_usage_max
          job_memory_usages.max.to_f
        end

        private

        def collect_memory_usage
          if defined?(NewRelic)
            # The implementation prefers in-process counters where
            # available (jruby), use the /proc/#{$$}/status on Linux,
            # and fall back to ps everywhere else (different ps options
            # on different platforms).
            NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
          else
            -1
            # Can not afford to fail here because ALL stats are ALWAYS collected
            # fail 'Newrelic gem is required in order to collect memory usage stats '
          end
        end
      end
    end
  end
end
