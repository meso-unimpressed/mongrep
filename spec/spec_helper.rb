# frozen_string_literal: true
require 'simplecov'
SimpleCov.start

require 'logger'
require 'mongo'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'repository_pattern'

module DBSpecs
  def mongo_client
    @mongo_client ||= Mongo::Client.new(
      [ENV['MONGO_HOST'] || 'localhost'],
      database: 'repository_pattern_test',
      logger: Logger.new(STDOUT).tap { |logger| logger.level = Logger::WARN }
    )
  end
end

RSpec.shared_context 'db specs' do
  include DBSpecs

  around do |example|
    begin
      example.run
    ensure
      mongo_client.database.drop
    end
  end
end

include RepositoryPattern
