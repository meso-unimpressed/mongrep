# frozen_string_literal: true
require 'spec_helper'
require 'mongrep/mongo_model'

describe MongoModel do
  subject(:record) { model.new }

  let(:model) do
    Class.new(described_class) do
      attribute :_id, Integer, required: false
      attribute :one, String, required: false
      attribute :two, Integer, required: false
    end
  end

  %i(_id id).each do |method|
    describe '##{method}' do
      let(:model) { Class.new(described_class) }

      it { is_expected.to respond_to(method) }

      it 'raises an AbstractError if not implemented' do
        expect { record.public_send(method) }.to raise_error(AbstractError)
      end
    end
  end

  describe '#new' do
    it 'instantiates the record from hash' do
      expect(model.new(_id: 1, one: 'test', two: 3)).to be_instance_of(model)
    end

    it 'sets the id from the hash' do
      expect(model.new(_id: 1, one: 'test', two: 3).id).to eq(1)
    end
  end

  it { is_expected.to respond_to(:to_bson) }
  it { is_expected.to respond_to(:bson_type) }
end
