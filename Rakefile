# encoding: utf-8

require "bundler/gem_tasks"

require 'rake'
require 'rake/testtask'

require File.dirname(__FILE__) + '/lib/resque-job-stats'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = Resque::Plugins::JobStats::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "resque-job-stats #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
