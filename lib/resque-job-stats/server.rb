require 'resque/server'

module Resque
  module Plugins
    module JobStats
      module Server
        VIEW_PATH = File.join(File.dirname(__FILE__), 'server', 'views')
        PUBLIC_PATH = File.join(File.dirname(__FILE__), 'server', 'public')

        def job_stats_to_display
          @job_stats_to_display ||= Resque::Plugins::JobStats::Statistic::DEFAULT_STATS
        end

        # Set this to an array of the public accessor names in Resque::Plugins::JobStats::Statistic
        # that you wish to display.  The default is [:jobs_enqueued, :jobs_performed, :jobs_failed, :job_rolling_avg, :longest_job]
        # Examples:
        #   Resque::Server.job_stats_to_display = [:jobs_performed, :job_rolling_avg]
        def job_stats_to_display=(stats)
          @job_stats_to_display = stats
        end

        module Helpers
          def display_stat?(stat_name)
            self.class.job_stats_to_display == :all ||
              [self.class.job_stats_to_display].flatten.map(&:to_sym).include?(stat_name.to_sym)
          end

          def time_display(float)
            float.zero? ? "" : ("%.2f" % float.to_s) + "s"
          end

          def number_display(num)
            num.zero? ? "" : num
          end

          def stat_header(stat_name)
            if(display_stat?(stat_name))
              "<th>" + stat_name.to_s.gsub(/_/,' ').capitalize + "</th>"
            end
          end

          def display_stat(stat, stat_name, format)
            if(display_stat?(stat_name))
              formatted_stat = self.send(format, stat.send(stat_name))
              "<td>#{formatted_stat}</td>"
            end
          end

          def check_or_cross_stat(value)
            value ? "&#x2713;" : "&#x2717;"
          end

          def render_public_file(filename)
            file = File.join(PUBLIC_PATH, filename)
              cache_control :public, :max_age => 86400
              send_file file
          rescue Errno::ENOENT
            status 404
          end
        end

        class << self
          def registered(app)
            app.get '/job_stats' do
              key = params.keys.first
              if key == 'js'
                render_public_file(params[key])
              else
                @jobs = Resque::Plugins::JobStats::Statistic.find_all(self.class.job_stats_to_display).sort
                erb(File.read(File.join(VIEW_PATH, 'job_stats.erb')))
              end
            end
            # We have little choice in using this funky name - Resque
            # already has a "Stats" tab, and it doesn't like
            # tab names with spaces in it (it translates the url as job%20stats)
            app.tabs << "Job_Stats"

            app.get '/job_history/:job_class' do
              @job_class = Resque::Plugins::JobStats.measured_jobs.find { |j| j.to_s == params[:job_class] }
              pass unless @job_class

              @start = 0
              @start = params[:start].to_i if params[:start]
              @limit = 100
              @limit = params[:limit].to_i if params[:limit]

              @histories = @job_class.job_histories(@start,@limit)
              @size = @job_class.histories_recorded

              erb(File.read(File.join(VIEW_PATH, 'job_histories.erb')))
            end

            app.get '/job_stats/timeseries/:job_class' do
              @job_class = Resque::Plugins::JobStats.measured_jobs.find { |j| j.to_s == params[:job_class] }
              pass unless @job_class

              @interval = params[:interval] == 'minute' ? 'minute' : 'hour'
              other_interval_label = params[:interval] == 'minute' ? 'hour' : 'minute'
              @toggle_interval_url = "#{request.path_info}?interval=#{other_interval_label}"

              if @job_class.respond_to?("queued_per_#{@interval}")
                @enqueued = @job_class.public_send("queued_per_#{@interval}").to_a
              else
                @enqueued = nil
              end

              if @job_class.respond_to?("performed_per_#{@interval}")
                @performed = @job_class.public_send("performed_per_#{@interval}").to_a
              else
                @performed = nil
              end

              erb(File.read(File.join(VIEW_PATH, 'job_timeseries.erb')))
            end

            app.helpers(Helpers)
          end
        end
      end
    end
  end
end

Resque::Server.register Resque::Plugins::JobStats::Server
