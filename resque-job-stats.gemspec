lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'resque/plugins/job_stats/version'

Gem::Specification.new do |s|
  s.name = "resque-job-stats"
  s.version = "#{Resque::Plugins::JobStats::VERSION}"

  s.authors = ["alanpeabody"]
  s.description = "Tracks jobs performed, failed, and the duration of the last 100 jobs for each job type."
  s.email = "gapeabody@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]

  files = `git ls-files`.split("\n") rescue []
  files &= (
    Dir['lib/**/*.{rb,erb}'] +
    Dir['*.md'])

  s.files         = files
  s.require_paths = ["lib"]

  s.homepage = "http://github.com/alanpeabody/resque-job-stats"
  s.licenses = ["MIT"]
  s.required_ruby_version = ">= 1.9.2"
  
  s.summary = "Job-centric stats for Resque"

  s.add_dependency('resque', '~> 1.17')

  s.add_development_dependency "rake"
  s.add_development_dependency "minitest", '~> 5.0'
  s.add_development_dependency "timecop", '~> 0.6'
  s.add_development_dependency 'rack-test', '>= 0'
end
