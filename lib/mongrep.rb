# frozen_string_literal: true
require 'mongrep/version'

# The top level namespace
module Mongrep
  # An error signaling an error with the configuration of the gem
  class ConfigurationError < RuntimeError; end

  module_function

  # @overload models_namespace
  #   Get the namespace where models are defined
  # @overload models_namespace(namespace)
  #   Set the namespace where models are defined
  #   @param namespace [Module] The namespace module to be set
  # @return [Module] the models namespace
  def models_namespace(namespace = nil)
    unless namespace || @models_namespace
      raise ConfigurationError, 'models namespace is unset'
    end

    namespace ? @models_namespace = namespace : @models_namespace
  end
end
