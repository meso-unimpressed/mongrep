# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'repository_pattern/version'

Gem::Specification.new do |spec|
  spec.name          = 'repository_pattern'
  spec.version       = RepositoryPattern::VERSION
  spec.authors       = ['Joakim Reinert']
  spec.email         = ['reinert@meso.net']

  spec.summary       = 'Provides base clases for the repository pattern'
  spec.description   =
    'Contains base classes for Models, Repositories and Queries to be used' \
    'in any project using MongoDB'
  spec.homepage      = 'https://git.meso.net/energybox/repository_pattern'

  spec.metadata['allowed_push_host'] = 'http://none.invalid'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.1'
  spec.add_development_dependency 'rake', '~> 11.2'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rubocop', '~> 0.4'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.7'
  spec.add_development_dependency 'pry', '~> 0.1'
  spec.add_development_dependency 'pry-byebug', '~> 3.4'
  spec.add_development_dependency 'simplecov', '~> 0.1'
  spec.add_development_dependency 'guard', '~> 2.1'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'guard-yard', '~> 2.1'
  spec.add_development_dependency 'libnotify', '~> 0.9'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-classmethods', '~> 1.0'
  spec.add_development_dependency 'factory_girl', '~> 4.7'

  spec.add_dependency 'abstractize', '~> 0.1'
  spec.add_dependency 'mongo', '~> 2.3'
  spec.add_dependency 'virtus', '~> 1.0'
  spec.add_dependency 'activesupport', '~> 5.0'
end
