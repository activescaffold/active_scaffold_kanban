# frozen_string_literal: true

require 'bundler/gem_tasks'

require 'rake/testtask'

desc 'Run tests.'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task default: :test
