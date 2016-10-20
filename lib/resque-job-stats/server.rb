require 'resque/server'

module Resque
  module Plugins
    module JobStats
      module Server
        VIEW_PATH = File.join(File.dirname(__FILE__), 'server', 'views')

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

        def job_stats
          Resque::Plugins::JobStats::Statistic.find_all(job_stats_to_display).sort
        end

        module Helpers 
          def layout_header
            header =  '<h1>Resque Job Stats</h1>
                        <p class="intro">
                          This page displays statistics about jobs that have been executed.
                        </p>'
            header += 'Timeseries data: <a href="job_stats_timeseries_minute">minute</a> | <a href="job_stats_timeseries_hour">hour</a>' if one_or_more_timeseries_stats_are_included?
          end

          def display_stat?(stat_name)
            self.class.job_stats_to_display == :all ||
              [self.class.job_stats_to_display].flatten.map(&:to_sym).include?(stat_name.to_sym)
          end

          def one_or_more_timeseries_stats_are_included?
            Resque::Plugins::JobStats::Statistic::TIME_SERIES_STATS.each {|stat_name| return true if display_stat?(stat_name) }
            return false
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

          # returns a hash of timeseries dates and values
          def timeseries_iterator(stat, time_type)
            Resque::Plugins::JobStats::Statistic::TIME_SERIES_STATS.each do |stat_name| 
              next unless stat_name.match(/#{time_type}/)
              if display_stat?(stat_name)
                return stat.send(stat_name)
              end
            end
            {}
          end

          def timeseries_lookup(stat, stat_name, time)
            if display_stat?(stat_name)
              "<td>#{timeseries_lookup_data(stat, stat_name, time)}</td>" 
            end
          end

          def timeseries_lookup_data(stat, stat_name, time)
            stat.send(stat_name)[time]
          end

          def pending_average(stat, stat_name, divisor_name, time)
            if display_stat?(stat_name) && display_stat?(divisor_name) 
              divisor = stat.send(divisor_name)[time]
              "<td>#{divisor != 0 ? (timeseries_lookup_data(stat, stat_name, time).to_f / divisor).round(2) : 0}</td>"
            end
          end

          def display_stat(stat, stat_name, format)
            if(display_stat?(stat_name))
              formatted_stat = self.send(format, stat.send(stat_name))
              "<td>#{formatted_stat}</td>"
            end
          end

        end

        class << self
          def registered(app)
            app.get '/job_stats' do
              @jobs = self.class.job_stats
              erb(File.read(File.join(VIEW_PATH, 'job_stats.erb')))
            end

            app.get '/job_stats_timeseries_minute' do
              @jobs = self.class.job_stats
              erb(File.read(File.join(VIEW_PATH, 'job_stats_timeseries_minute.erb')))
            end

            app.get '/job_stats_timeseries_hour' do
              @jobs = self.class.job_stats
              erb(File.read(File.join(VIEW_PATH, 'job_stats_timeseries_hour.erb')))
            end

            # We have little choice in using this funky name - Resque
            # already has a "Stats" tab, and it doesn't like
            # tab names with spaces in it (it translates the url as job%20stats)
            app.tabs << "Job_Stats"

            app.helpers(Helpers)
          end
        end
      end
    end
  end
end

Resque::Server.register Resque::Plugins::JobStats::Server
