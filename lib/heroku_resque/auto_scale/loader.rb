require 'yaml'

module HerokuResque
  module AutoScale
    module Loader
      class << self
        def job_counts
          @job_counts ||= YAML.open(path)['worker_maxjobs']
        end

        attr_writer :file_name
        def file_name
          @file_name = ||= 'worker_auto_scale.yml'
        end

        def path
          Rails.root.join('config', 'heroku', file_name)
        end
      end
    end      
  end
end