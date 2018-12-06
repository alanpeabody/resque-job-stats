module Resque
  module Plugins
    module JobStats
      module MeasuredHook

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def extended(base)
            Resque::Plugins::JobStats.add_measured_job(base)
          end
        end

        def inherited(subclass)
          subclass.extend Resque::Plugins::JobStats
        end

      end
    end
  end
end
