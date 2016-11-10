# frozen_string_literal: true
module Mongrep
  # A mongodb query object
  class Query
    # @param query_hash [Hash] A hash representing the query
    # @example
    #   Query.new(name: 'test')
    def initialize(query_hash = {})
      @query_hash = query_hash.to_h
    end

    # Combines two queries by merging their underlying query hashes
    # @param other [Query] The query to combine self with
    # @return [Query] A new Query instance resulting in the combination of
    #   self and other
    # @example
    #   first = Query.new(name: 'test', value: 5)
    #   second = Query.new(value: 6)
    #   (first & second).to_h #=> { name: 'test', value: 6 }
    def &(other)
      self.class.new(@query_hash.merge(other.to_h))
    end

    # Combines two queries by using the MongoDB $or operator
    # @param other [Query] The query to combine self with
    # @return [Query] A new Query instance resulting in the combination of
    #   self and other
    # @example
    #   first = Query.new(name: 'foo')
    #   second = Query.new(name: 'bar')
    #   (first | second).to_h
    #   #=> { :$or => [{ name: 'foo' }, { name: 'bar' }] }
    def |(other)
      self.class.new(:$or => [@query_hash, other.to_h])
    end

    # Combines self with the given query hash by merging it to the
    # existing one
    # @param query_hash [Hash] The query hash to merge into the query
    # @return [Query] A new Query resulting in the combination of the
    #   given query hash and the existing one
    # @example
    #   query.where(name: 'test')
    # @note This is mainly for usage in Repository#find using a block
    # @see #&
    # @see Repository Repository#find
    def where(query_hash)
      self & self.class.new(query_hash)
    end

    # Combines self with the given query hash by using the MongoDB $or
    # operator
    # @param query_hash [Hash] The query hash to combine with the query
    # @return [Query] A new Query resulting in the combination of the
    #   given query hash and the existing one
    # @see #|
    # @example
    #   query.where(name: 'foo').or(name: 'bar')
    def or(query_hash)
      self | self.class.new(query_hash)
    end

    alias and where

    # @return [Hash] The underlying query hash
    def to_h
      @query_hash
    end
  end
end
