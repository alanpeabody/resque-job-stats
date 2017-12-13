require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/mock'
require 'rack/test'
require 'resque'
require 'timecop'

Resque.redis = 'localhost:6379'
Resque.redis.namespace = 'resque:job_stats'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'resque-job-stats'

