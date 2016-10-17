# frozen_string_literal: true
require 'mongo'

module RepositoryPattern
  module CoreExt
    # Core extensions to Mongo
    module Mongo
      # Core extensions to Mongo::Error
      module Error
        # Core extensions to Mongo::Error::OperationFailure
        module OperationFailure
          def duplicate_key_error?
            message.start_with?('E11000')
          end

          ::Mongo::Error::OperationFailure.include(self)
        end
      end
    end
  end
end
