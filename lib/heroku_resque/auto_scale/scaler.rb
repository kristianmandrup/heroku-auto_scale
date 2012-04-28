module HerokuResque
  module AutoScale
    module Scaler
      class << self
        @@heroku = Heroku::Client.new(ENV['HEROKU_USER'], ENV['HEROKU_PASS'])

        def workers
          case HerokuStack.name.to_sym
          when :cedar            
            @@heroku.ps(ENV['HEROKU_APP']).count { |a| a["process"] =~ /worker/ }
          else
            @@heroku.info(ENV['HEROKU_APP'])[:workers].to_i
          end
        end

        def workers=(qty)
          case HerokuStack.name.to_sym
          when :cedar
            @@heroku.ps_scale(ENV['HEROKU_APP'], :type=>'worker', :qty=>qty)
          else
            @@heroku.set_workers(ENV['HEROKU_APP'], qty)
          end          
        end

        def working_count
          Resque.info[:working].to_i
        end

        def job_count
          Resque.info[:pending].to_i
        end
      end
    end
  end
end