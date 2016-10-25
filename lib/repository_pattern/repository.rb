# frozen_string_literal: true
require 'active_support/inflector'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/slice'
require 'repository_pattern/core_ext/hash'
require 'abstractize'
require 'repository_pattern/query'
require 'repository_pattern/query_result'
require 'repository_pattern/core_ext/mongo/error/operation_failure'

module RepositoryPattern
  # @abstract The base class for all repositories
  class Repository
    include Abstractize

    # An error signaling that a document could not be found
    class DocumentNotFoundError < RuntimeError; end
    # An error signaling that a model has not been persisted
    class UnpersistedModelError < ArgumentError; end
    # An error signaling that a document already exists
    class DocumentExistsError < ArgumentError; end

    attr_reader :collection

    # @param mongo_client [Mongo::Client] The mongodb client to use
    def initialize(mongo_client)
      @collection = mongo_client[collection_name]
    end

    # Derives the collection name from the class name
    # @return [String] The underscored collection name
    # @example
    #   repository = Shop::ShoppingCarts.new(mongo_client)
    #   repository.collection_name #=> 'shopping_carts'
    def collection_name
      self.class.name.demodulize.underscore
    end

    # Derives the model class from the class name, requires and returns it
    # @return [Model.class] The model class for this repository
    # @example
    #   repository = Shop::ShoppingCarts.new(mongo_client)
    #   repository.model_class #=> Shop::Models::ShoppingCart
    def model_class
      model_name = self.class.name.demodulize.singularize
      RepositoryPattern.models_namespace.const_get(model_name)
    end

    # Finds documents matching the given query
    # @overload find(query)
    #   @param query [Hash, Query] The mongodb query to perform
    # @overload find(query, options)
    #   @param query [Hash, Query] The mongodb query to perform
    #   @param options [Hash] Options to pass to the query
    # @overload find
    #   @yieldparam query [Query] A new query
    #   @yieldreturn [Query] The query to be used
    # @overload find(query)
    #   @param query [Hash, Query] The initial query
    #   @yieldparam query [Query] The query object
    #   @yieldreturn [Query] The final query to be used
    # @overload find(query, options)
    #   @param query [Hash, Query] The initial query
    #   @param options [Hash] Options to pass to the query
    #   @yieldparam query [Query] The query object
    #   @yieldreturn [Query] The final query to be used
    # @return [QueryResult<Model>] An enumerable query result
    # @example With query hash
    #   result = repository.find(name: 'test')
    # @example With Query object
    #   repeating_query = Query.new(name: 'test')
    #   result = repository.find(repeating_query)
    # @example With code block
    #   result = repository.find do |query|
    #     query.where(name: 'test 1').or(name: 'test 2')
    #   end
    # @example With query hash and options
    #   result = repository.find({ name: 'test' }, limit: 1)
    # @see Query
    # @see QueryResult
    def find(query = {}, options = {})
      query_object = query.is_a?(Hash) ? Query.new(query) : query
      query_object = yield(query_object) if block_given?
      execute_query(query_object, options)
    end

    # Finds a single document matching the given query
    # @overload find_one(query)
    #   @param query [Hash, Query] The mongodb query to perform
    # @overload find_one(query, options)
    #   @param query [Hash, Query] The mongodb query to perform
    #   @param options [Hash] Options to pass to the query
    # @overload find_one
    #   @yieldparam query [Query] A new query
    #   @yieldreturn [Query] The query to be used
    # @overload find_one(query)
    #   @param query [Hash, Query] The initial query
    #   @yieldparam query [Query] The query object
    #   @yieldreturn [Query] The final query to be used
    # @overload find_one(query, options)
    #   @param query [Hash, Query] The initial query
    #   @param options [Hash] Options to pass to the query
    #   @yieldparam query [Query] The query object
    #   @yieldreturn [Query] The final query to be used
    # @raise [DocumentNotFoundError] if no matching document could be found
    # @return [Model] The single model instance representing the document
    #   matching the query
    def find_one(query = {}, options = {}, &block)
      # TODO: Pass some context to DocumentNotFoundError
      find(query, options, &block).first || raise(DocumentNotFoundError)
    end

    # Inserts a document into the database
    # @param model [Model] The model representing the document to be inserted
    # @return [Mongo::Operation::Write::Insert::Result] The result of the
    #   insert operation
    def insert(model)
      collection.insert_one(model.to_h)
    rescue Mongo::Error::OperationFailure => error
      # TODO: Pass relevant info to DocumentExistsError message
      raise(error.duplicate_key_error? ? DocumentExistsError : error)
    end

    # Update an existing document in the database
    # @param model [Model] The model representing the document to be updated
    # @option options [Array<String>] :fields The specific fields to update.
    #   If this option is omitted the whole document is updated
    # @raise [UnpersistedModelError] if the model is not persisted
    #   (has no value for _id)
    # @raise [DocumentNotFoundError] if nothing was updated
    #   (no document found for _id)
    # @return [Mongo::Operation::Write::Update::Result] The result of the
    #   update operation
    def update(model, options = {})
      check_persistence!(model)
      result = collection.update_one(
        id_query(model),
        update_hash(model, options[:fields])
      )
      # TODO: Pass some context to DocumentNotFoundError
      raise(DocumentNotFoundError) if result.documents.first['n'].zero?
      result
    end

    # TODO: implement upsert

    # Delete an existing document from the database
    # @param model [Model] The model representing the document to be updated
    # @raise [UnpersistedModelError] if the model is not persisted
    #   (has no value for _id)
    # @raise [DocumentNotFoundError] if nothing was deleted
    #   (no document found for _id)
    # @return [Mongo::Operation::Write::Delete::Result] The result of the
    #   delete operation
    def delete(model)
      check_persistence!(model)
      result = collection.delete_one(id_query(model))
      # TODO: Pass some context to DocumentNotFoundError
      raise(DocumentNotFoundError) if result.documents.first['n'].zero?
      result
    end

    # Get a distinct list of values for the given field over all documents
    # in the collection.
    # @param field [Symbol, String] The field or dot notated path to the
    #   field
    # @return [Array] An array with the distinct values
    def distinct(field)
      collection.distinct(field)
    end

    private

    def update_hash(model, fields_to_set = nil)
      model_fields = model.to_h.except(:_id)
      return model_fields unless fields_to_set
      { :$set => model_fields.slice_with_dot_notation(*fields_to_set) }
    end

    def id_query(model)
      { _id: model._id }
    end

    def execute_query(query_object, options)
      check_query_type!(query_object)
      QueryResult.new(collection.find(query_object.to_h, options), model_class)
    end

    def check_persistence!(model)
      return if model._id
      raise UnpersistedModelError, 'model is not yet persisted'
    end

    protected

    def check_query_type!(query_object)
      return if query_object.is_a?(Query)
      raise ArgumentError, 'Invalid type for query ' \
                           "(#{query_object.class.name})"
    end
  end
end
