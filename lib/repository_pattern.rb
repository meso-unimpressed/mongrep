# frozen_string_literal: true
require 'repository_pattern/version'

# The top level namespace
module RepositoryPattern
  class ConfigurationError < RuntimeError; end

  module_function

  def models_namespace(namespace = nil)
    unless namespace || @models_namespace
      raise ConfigurationError, 'models namespace is unset'
    end

    namespace ? @models_namespace = namespace : @models_namespace
  end
end
