module Resque
  module Plugins
    module JobStats
      module MeasuredHook

        def extended(base)
          Resque.redis.sadd("stats:jobs", base)
        end

      end
    end
  end
end
