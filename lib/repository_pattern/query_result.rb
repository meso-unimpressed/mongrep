# frozen_string_literal: true
module RepositoryPattern
  # A wrapper around mongo cursors
  class QueryResult
    include Enumerable

    # The methods to be delegated to the underlying mongo cursor
    # @api private
    DELEGATED_METHODS = %i(limit projection skip sort).freeze

    attr_reader :model_class
    # @api private
    def initialize(collection_view, model_class)
      @model_class = model_class
      @collection_view = collection_view
    end

    DELEGATED_METHODS.each do |method|
      aggregation_stage = method == :projection ? :project : method

      define_method(method) do |param|
        if @collection_view.is_a?(Mongo::Collection::View::Aggregation)
          @collection_view.pipeline << { :"$#{aggregation_stage}" => param }
        else
          @collection_view = @collection_view.public_send(method, param)
        end

        self
      end
    end

    # Iterates over the query result
    # @yieldparam item [Model] A model representing a document from the
    #   query result
    # @return [void]
    def each
      return enum_for(:each) unless block_given?

      @collection_view.each do |document|
        yield @model_class.new(document)
      end
    end
  end
end
