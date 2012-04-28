require 'heroku_resque/auto_scale/scaler'
require 'heroku_resque/auto_scale/loader'

module HerokuResque
  module AutoScale
    def after_perform_scale_down(*args)
      # Nothing fancy, just shut everything down if we have no jobs
      Scaler.workers = 0 if Scaler.job_count.zero?
    end

    attr_writer :auto_scale_config

    class << self
      attr_writer :default_config, :job_counts

      def load_job_counts!
        self.job_counts = HerokuResque::AutoScale::Loader.job_counts
      end

      def job_counts
        @job_counts ||= [1, 15, 25, 40, 60, 100, 150]
      end

      def default_config
        (1..5).to_a.map do |workers|
          worker_config workers
        end
      end

      protected

      def worker_config workers
        {:workers => workers, :job_count => job_counts[workers]}
      end      
    end     

    # To adjust:
    #
    #   auto_scale_config[2] = {:workers => 2, :job_count => 20}
    #
    def auto_scale_config
      @auto_scale_config ||= HerokuResque::AutoScale.default_config
    end      

    def after_enqueue_scale_up(*args)
      auto_scale_config.reverse_each do |scale_info|
        # Run backwards so it gets set to the highest value first
        # Otherwise if there were 70 jobs, it would get set to 1, then 2, then 3, etc

        # If we have a job count greater than or equal to the job limit for this scale info
        if Scaler.job_count >= scale_info[:job_count]
          # Set the number of workers unless they are already set to a level we want. Don't scale down here!
          if Scaler.workers <= scale_info[:workers]
            Scaler.workers = scale_info[:workers]
          end
          break # We've set or ensured that the worker count is high enough
        end
      end
    end
  end
end