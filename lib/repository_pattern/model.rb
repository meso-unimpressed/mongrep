# frozen_string_literal: true
require 'virtus'

module RepositoryPattern
  # A mixin providing Virtus.model functionality and a recursive to_h method
  module Model
    class << self
      private

      # The included method is used here to ensure correct order
      # of inclusion and method overrides
      def included(base)
        base.include(Virtus.model(strict: true))
        base.include(VirtusExtensions)
        base.extend(ClassMethods)
      end
    end

    # Static methods of Shells
    module Shell
      # @return [String] A human readable string representation of the
      #   instance
      def inspect
        instance_vars = instance_variables.map do |var|
          "#{var}=#{instance_variable_get(var).inspect}"
        end
        "#<#{self.class.inspect}:#{object_id} #{instance_vars.join(' ')}>"
      end

      # Static class methods for Shells
      module ClassMethods
        # @return [String] A human readable string representation of the
        #   class instance
        def inspect
          name
        end
      end
    end

    # Class methods for models
    # TODO: Clean this up
    # @!classmethods
    module ClassMethods
      def partial(*fields)
        class_name = "#{name}::Partial[#{fields.map(&:inspect).join(', ')}]"
        attributes = partial_attributes(*fields)
        Class.new do
          include Model
          include Shell
          extend Shell::ClassMethods

          define_singleton_method(:name) { class_name }
          attributes.each { |attribute| attribute_set << attribute }
        end
      end

      private

      def partial_attributes(*fields)
        field_hash = fields.last.is_a?(Hash) ? fields.pop : {}

        (fields + field_hash.keys).map do |name|
          attribute = attribute_set[name]
          nested_fields = field_hash[name]
          if nested_fields
            nested_partial_attribute(attribute, *nested_fields)
          else
            attribute
          end
        end
      end

      def nested_partial_attribute(attribute, *fields)
        type = nested_partial(attribute.type, *fields)
        options = attribute.options.slice(
          :primitive, :default, :strict, :required, :finalize,
          :nullify_blank, :reader, :writer, :name, :coerce
        )
        Virtus::Attribute.build(type, options)
      end

      def nested_partial(type, *fields)
        case type
        when Virtus::Attribute::Collection::Type
          type.primitive[type.member_type.partial(*fields)]
        when Virtus::Attribute::Hash::Type
          Hash[type.key_type.primitive => type.value_type.partial(*fields)]
        else type.primitive.partial(*fields)
        end
      end
    end

    # @!parse include VirtusExtensions

    # Extensions to Virtus models
    module VirtusExtensions
      # Converts the model into a hash. This supports nested models.
      # @return [Hash] A Hash representation of the models attributes
      def to_h
        result = {}
        super.each { |key, value| result[key] = hashify_value(value) }
        result
      end

      # Checks for equality between self and other
      # @param other [Model] Another Model
      # @return [true] If other has equal attributes
      # @return [false] otherwise
      def ==(other)
        return false unless other.is_a?(self.class)
        to_h == other.to_h
      end

      private

      def hashify_value(value)
        case value
        when Array then value.map(&method(:hashify_value))
        when Hash
          result = {}
          value.each { |k, v| result[k] = hashify_value(v) }
          result
        when Model then value.to_h
        else value
        end
      end
    end
  end
end
