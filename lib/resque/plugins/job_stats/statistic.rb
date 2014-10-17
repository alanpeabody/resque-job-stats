module Resque
  module Plugins
    module JobStats
      class JobPlaceholder
        include Resque::Plugins::JobStats::All

        def initialize(name)
          @name = name || fail
        end

        attr_reader :name
      end
      # A class composed of a job class and the various job statistics
      # collected for the given job.
      class Statistic
        include Comparable

        # An array of the default statistics that will be displayed in the web tab
        DEFAULT_STATS = [
          :jobs_enqueued, :jobs_performed, :jobs_failed, :job_rolling_avg,
          :longest_job, :job_memory_usage_rolling_avg, :job_memory_usage_max
        ]

        attr_accessor :entity, *DEFAULT_STATS

        class << self
          # Find and load a Statistic for all resque jobs that left their stats in redis
          def find_all(metrics)
            measured_jobs.uniq.sort.map { |name|
              new(measurable_entity(name), metrics)
            }
          end

          private

          # Find names of all resque jobs that left their stats in redis
          def measured_jobs
            Resque.redis.keys('stats:jobs:*').map { |o| o.split(/(?<!:):(?!:)/)[2] }
          end

          def measurable_entity(name)
            JobPlaceholder.new(name)
          end
        end

        # A series of metrics describing one job class.
        def initialize(entity, metrics)
          self.entity = entity
          self.load(metrics)
        end

        def load(metrics)
          metrics.each do |metric|
            self.send("#{metric}=", entity.send(metric))
          end
        end

        def name
          self.entity.name
        end

        def <=>(other)
          self.name <=> other.name
        end
      end
    end
  end
end
