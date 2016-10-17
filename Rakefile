# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'
require 'json'

require 'repository_pattern/version'

RSpec::Core::RakeTask.new(:spec)

task default: :test

task test: [:spec, :rubocop]

RuboCop::RakeTask.new
