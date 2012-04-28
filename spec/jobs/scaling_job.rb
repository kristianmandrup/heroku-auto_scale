class ScalingJob
  extend HerokuResque::AutoScale

  def self.perform
    # Do something long running
  end
end