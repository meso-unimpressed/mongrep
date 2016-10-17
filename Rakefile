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

namespace :doc do
  desc 'alias for yard task'
  task generate: :yard

  desc 'deploy documentation'
  task deploy: :generate do
    doc_deploy_path =
      'docdeploy@eb-doc.meso.net:/srv/http/doc/repository_pattern'
    system(
      'rsync', '-r', '--delete', '-v',
      '-e', 'ssh -o StrictHostKeyChecking=no',
      "#{File.expand_path('../doc/yardoc', __FILE__)}/",
      "#{doc_deploy_path}/#{RepositoryPattern::VERSION}/"
    ) || abort('command exited with non-zero exit status')
  end
end
