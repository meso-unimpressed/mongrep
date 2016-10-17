# frozen_string_literal: true

guard :rspec, cmd: 'bundle exec rspec' do
  require 'guard/rspec/dsl'
  dsl = Guard::RSpec::Dsl.new(self)

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  watch(ruby.lib_files) do |m|
    spec_path = m[1][%r{(?<=lib/).*}]
    [
      rspec.spec.call("unit/#{spec_path}"),
      rspec.spec.call("integration/#{spec_path}")
    ]
  end

  # Shared examples
  watch(%r{(spec/.+)/shared_examples/.*\.rb}) { |m| m[1] }
end

guard 'yard' do
  watch(%r{app/.+\.rb})
  watch(%r{lib/.+\.rb})
  watch(%r{ext/.+\.c})
end
