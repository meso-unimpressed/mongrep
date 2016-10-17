# frozen_string_literal: true
require 'abstractize'
require 'active_support/core_ext/hash/indifferent_access'

require 'repository_pattern/model'

module RepositoryPattern
  # @abstract The base class for all models
  class MongoModel
    include Abstractize
    include Model

    define_abstract_method :_id

    # An alias for #_id
    def id
      _id
    end

    # Used by Mongo to convert the model into BSON
    # @api private
    def bson_type
      Hash::BSON_TYPE
    end

    # Used by Mongo to convert the model into BSON
    # @api private
    def to_bson(*args)
      to_h.to_bson(*args)
    end
  end
end
