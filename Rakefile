# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'erb'
require 'yard'
require 'json'

require 'mongrep/version'

RSpec::Core::RakeTask.new(:spec)

task default: :test

task test: [:spec, :rubocop]

RuboCop::RakeTask.new

Rake::Task['release:guard_clean'].enhance do
  begin
    system('git stash')
    erb = ERB.new(File.read(File.expand_path('../README.md.erb', __FILE__)))
    File.write(File.expand_path('../README.md', __FILE__), erb.result)
    system('git add README.md')
    system('git commit -m "Update gem version in readme"')
  ensure
    system('git stash pop')
  end
end
