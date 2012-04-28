# Heroku Auto-scale

Adapted from: [Auto-scale Your Resque Workers On Heroku](https://gist.github.com/501160)

## Configure auto-scaling

The `job_counts` is list that is used to define how many jobs are run for the number of workers as determined by the index in the list:

```ruby
HerokuResque::AutoScale.job_counts[2] = 22 # 22 max jobs for 2 workers
HerokuResque::AutoScale.job_counts = [1,4,8,16,32,64]
```

## Usage

```ruby
class ScalingJob
  extend HerokuResque::AutoScale

  def self.perform
    # Do something long running
  end
end
```

## Configure Heroku stack used

By default this gem assumes you are running on the 'cedar' stack.
You can customize the Heroku stack used like this:

`HerokuStack.name = 'my-stack'`

We might have to adjust the code in order to support different stacks with different Process models in the future...

## Contributing to heroku-auto_scale
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 Kristian Mandrup. See LICENSE.txt for
further details.

