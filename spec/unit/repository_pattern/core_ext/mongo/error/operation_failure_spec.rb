# frozen_string_literal: true
require 'spec_helper'
require 'mongrep/core_ext/mongo/error/operation_failure'

describe Mongo::Error::OperationFailure do
  context '#operation_failure?' do
    let(:duplicate_key_error) { described_class.new('E11000 error') }
    let(:other_error) { described_class.new('E99999 error') }

    it 'returns true if error code E11000' do
      expect(duplicate_key_error).to be_duplicate_key_error
    end

    it 'returns false if error code not E11000' do
      expect(other_error).not_to be_duplicate_key_error
    end
  end
end
