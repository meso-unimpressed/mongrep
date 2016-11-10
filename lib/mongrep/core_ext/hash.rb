# frozen_string_literal: true
require 'active_support/core_ext/hash/indifferent_access'

module Mongrep
  # Top level namespace for all core extensions
  module CoreExt
    # Core extensions to Hash class
    module Hash
      # Produces a hash containing only given keys which can be in dot
      # notation
      # @param keys [<String, Symbol>] the keys to include in the resulting
      #   hash. Note that they are stringified and self will be accessed
      #   with indifferent access.
      # @return [{String => Object}] the hash including only the selected
      #   stringified keys
      # @example
      #   hash = { foo: { bar: 'foobar' }, bar: 'foo' }
      #   hash.slice_with_dot_notation('foo.bar')
      #   #=> { 'foo.bar' => 'foobar' }
      def slice_with_dot_notation(*keys)
        keys.map(&:to_s).each_with_object(self.class.new) do |key, hash|
          path = key.to_s.split('.')

          catch :missing_key do
            hash[key] = path.reduce(with_indifferent_access) do |level, part|
              throw :missing_key unless level.key?(part)
              level[part]
            end
          end
        end
      end

      ::Hash.include(self)
    end
  end
end
