# Resque-Job-Stats demo

Basic rack app showing resque-job-stats UI.

```ruby
cd examples/sinatra
bundle install
rackup # start resque web server

# in another terminal window
QUEUE=* rake resque:work

# in another terminal window
rake enqueue_success
rake enqueue_failure
# can also specify counts
SUCCESS_JOBS=10 rake enqueue_success
```
