# frozen_string_literal: true

require 'mongrep/repository'
module Mongrep
  # A mixin providing overwrites for write methods in read-only repositories
  module ReadOnlyRepository
    # An error signaling that the write operation isn't possible
    class WriteError < ArgumentError; end

    # @!method insert(*)
    #   @raise [WriteError] - Always raises
    # @!method update(*)
    #   @raise [WriteError] - Always raises
    # @!method delete(*)
    #   @raise [WriteError] - Always raises
    %i(insert update delete).each do |method|
      define_method(method) do |*|
        raise WriteError, 'this repository is read-only'
      end
    end
  end
end
