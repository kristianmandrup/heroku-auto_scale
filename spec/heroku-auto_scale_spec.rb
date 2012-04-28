require 'spec_helper'

class HerokuResqueAutoScaleTestClass
  extend HerokuResque::AutoScale
end

it "is extended by the Heroku autoscale module if configatron.resque.autoscale is set in configuration" do
  begin
    # Set the configuration to autoscale = true and reload this class
    # which is necessary because by the time this test is running, the class has already loaded
    configatron.resque.autoscale = true
    load File.expand_path('../../../../lib/jobs/background_worker.rb', __FILE__)

    module Kernel
      def eigenclass
        class << self
          self
        end
      end
    end
    BackgroundWorker.eigenclass.included_modules.include?(HerokuResque::AutoScale)
  ensure
    configatron.resque.autoscale = false
  end
end

describe HerokuResque::AutoScale do
  before :all do
    ENV['HEROKU_USER'] ||= "heroku_user"
    ENV['HEROKU_PASS'] ||= "heroku_pass"
    ENV['HEROKU_APP'] ||= "heroku_app"
  end

  before :each do
    @heroku = mock(Heroku::Client)
    HerokuResque::AutoScale::Scaler.class_variable_set(:@@heroku, @heroku)
  end

  let(:heroku_app) {ENV['HEROKU_APP']}

  context "#workers" do
    it "returns the number of workers from the Heroku application" do
      num_workers = 100
      @heroku.should_receive(:info).with(heroku_app).and_return({:workers => num_workers})
      HerokuResqueAutoScale::Scaler.workers.should == num_workers
    end
  end

  context "#workers=" do
    it "sets the number of workers on Heroku to some quantity" do
      quantity = 10
      @heroku.should_receive(:set_workers).with(heroku_app, quantity)
      HerokuResqueAutoScale::Scaler.workers = quantity
    end
  end

  context "#job_count" do
    it "returns the Resque job count" do
      num_pending = 10
      Resque.should_receive(:info).and_return({:pending => num_pending})
      HerokuResqueAutoScale::Scaler.job_count.should == num_pending
    end
  end

  context "#num_desired_heroku_workers" do
    it "returns the number of workers we should have (1 worker per x jobs)" do
      num_jobs = 100
      HerokuResqueAutoScale::Scaler.stub(:job_count).and_return(num_jobs)
      HerokuResqueAutoScaleTestClass.num_desired_heroku_workers.should == (num_jobs.to_f / HerokuResqueAutoScale::Scaler::NUM_JOBS_PER_WORKER).ceil

      num_jobs = 38
      HerokuResqueAutoScale::Scaler.unstub(:job_count)
      HerokuResqueAutoScale::Scaler.stub(:job_count).and_return(num_jobs)
      HerokuResqueAutoScaleTestClass.num_desired_heroku_workers.should == (num_jobs.to_f / HerokuResqueAutoScale::Scaler::NUM_JOBS_PER_WORKER).ceil

      num_jobs = 1
      HerokuResqueAutoScale::Scaler.unstub(:job_count)
      HerokuResqueAutoScale::Scaler.stub(:job_count).and_return(num_jobs)
      HerokuResqueAutoScaleTestClass.num_desired_heroku_workers.should == (num_jobs.to_f / HerokuResqueAutoScale::Scaler::NUM_JOBS_PER_WORKER).ceil

      num_jobs = 10000
      HerokuResqueAutoScale::Scaler.unstub(:job_count)
      HerokuResqueAutoScale::Scaler.stub(:job_count).and_return(num_jobs)
      HerokuResqueAutoScaleTestClass.num_desired_heroku_workers.should == (num_jobs.to_f / HerokuResqueAutoScale::Scaler::NUM_JOBS_PER_WORKER).ceil
    end
  end

  context "#after_perform_scale_down" do
    it "scales down the workers to zero if there are no jobs pending" do
      HerokuResqueAutoScale::Scaler.stub(:job_count).and_return(0)
      HerokuResqueAutoScale::Scaler.should_receive(:workers=).with(0)
      HerokuResqueAutoScaleTestClass.after_perform_scale_down
    end

    it "does not scale down the workers if there are jobs pending" do
      HerokuResqueAutoScale::Scaler.stub(:job_count).and_return(1)
      HerokuResqueAutoScale::Scaler.should_not_receive(:workers=)
      HerokuResqueAutoScaleTestClass.after_perform_scale_down
    end
  end

  context "#after_enqueue_scale_up" do
    it "ups the amount of workers if there are not enough" do
      num_workers = 5
      num_desired_workers = 6
      HerokuResqueAutoScale::Scaler.stub(:workers).and_return(num_workers)
      HerokuResqueAutoScaleTestClass.stub(:num_desired_heroku_workers).and_return(num_desired_workers)
      HerokuResqueAutoScale::Scaler.should_receive(:workers=).with(num_desired_workers)
      HerokuResqueAutoScaleTestClass.after_enqueue_scale_up
    end

    it "does not change the amount of workers if there more workers than needed" do
      num_workers = 6
      num_desired_workers = 5
      HerokuResqueAutoScale::Scaler.stub(:workers).and_return(num_workers)
      HerokuResqueAutoScaleTestClass.stub(:num_desired_heroku_workers).and_return(num_desired_workers)
      HerokuResqueAutoScale::Scaler.should_not_receive(:workers=)
      HerokuResqueAutoScaleTestClass.after_enqueue_scale_up
    end

    it "does not change the amount of workers if there are exactly the number required" do
      num_workers = 6
      num_desired_workers = 6
      HerokuResqueAutoScale::Scaler.stub(:workers).and_return(num_workers)
      HerokuResqueAutoScaleTestClass.stub(:num_desired_heroku_workers).and_return(num_desired_workers)
      HerokuResqueAutoScale::Scaler.should_not_receive(:workers=)
      HerokuResqueAutoScaleTestClass.after_enqueue_scale_up
    end
  end
end