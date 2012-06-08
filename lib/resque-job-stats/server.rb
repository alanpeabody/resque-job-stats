require 'resque/server'

module Resque
  module Plugins
    module JobStats
      module Server
        VIEW_PATH = File.join(File.dirname(__FILE__), 'server', 'views')

        def self.registered(app)

          app.get '/job_stats' do
            @jobs = Resque::Plugins::JobStats::Statistic.find_all.sort
            erb(File.read(File.join(VIEW_PATH, 'job_stats.erb')))
          end

          # We have little choice in using this funky name - Resque
          # already has a "Stats" tab, and it doesn't like 
          # tab names with spaces in it (it translates the url as job%20stats)
          app.tabs << "Job_Stats"

          app.helpers do
            def time_display(float)
              float.zero? ? "" : ("%.2f" % float.to_s) + "s"
            end

            def number_display(num)
              num.zero? ? "" : num
            end
          end
        end
      end
    end
  end
end

Resque::Server.register Resque::Plugins::JobStats::Server