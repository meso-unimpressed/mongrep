# frozen_string_literal: true
module RepositoryPattern
  # A wrapper around mongo cursors
  class QueryResult
    include Enumerable

    # The methods to be delegated to the underlying mongo cursor
    # @api private
    DELEGATED_METHODS = %i(aggregate limit projection skip sort).freeze

    # @api private
    def initialize(mongo_cursor, model_class)
      @model_class = model_class
      @mongo_cursor = mongo_cursor
    end

    DELEGATED_METHODS.each do |method|
      define_method(method) do |*args|
        @mongo_cursor = @mongo_cursor.public_send(method, *args)
        self
      end
    end

    # Iterates over the query result
    # @yieldparam item [Model] A model representing a document from the
    #   query result
    # @return [void]
    def each
      return enum_for(:each) unless block_given?

      @mongo_cursor.each do |document|
        yield @model_class.new(document)
      end
    end
  end
end
