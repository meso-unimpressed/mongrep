unless ARGV.any? { |e| e =~ /guard-rspec/ }
  SimpleCov.start do
    coverage_dir 'log/coverage'
    formatter SimpleCov::Formatter::HTMLFormatter

    command_name 'rspec'
    maximum_coverage_drop 1
  end
end
