module Resque
  module Plugins
    module JobStats
      class Statistic
        include Comparable

        attr_accessor :job_class,
                      :jobs_enqueued,
                      :jobs_performed,
                      :jobs_failed,
                      :job_rolling_avg,
                      :longest_job

    
        class << self
          def find_all
            Resque::Plugins::JobStats.measured_jobs.map{|j| new(j)}
          end
        end

        def initialize(job_class)
          self.job_class = job_class
          self.jobs_enqueued =   job_class.jobs_enqueued
          self.jobs_enqueued =   job_class.jobs_enqueued
          self.jobs_performed =  job_class.jobs_performed
          self.jobs_failed =     job_class.jobs_failed / 2
          self.job_rolling_avg = job_class.job_rolling_avg
          self.longest_job =     job_class.longest_job
        end

        def name
          self.job_class.name
        end

        def <=>(other)
          self.name <=> other.name
        end
      end
    end
  end
end
