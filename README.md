# RepositoryPattern

This gem provides classes and modules for implementing persistance layers using
the repository pattern

## Installation

Add this line to your application's Gemfile:

```ruby
gem(
  'repository_pattern',
  git: 'git@git.meso.net:ds/repository_pattern',
  tag: 'v0.1.0'
)
```

And then execute:

    $ bundle

## Documentation

Documentation for the gem is available [here](https://eb-doc.meso.net/repository_pattern).
Credentials for the docs are found in the shared secrets.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version and push
git commits and tags. This will raise an exception when trying to push the gem,
which is expected and normal.
