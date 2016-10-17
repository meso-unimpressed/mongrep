# frozen_string_literal: true

require 'spec_helper'
require 'repository_pattern/repository'
require 'repository_pattern/mongo_model'

describe Repository do
  include_context 'db specs'

  let(:repository) do
    Class.new(described_class) do
      define_singleton_method(:name) { 'Tests' }
    end
  end

  let(:model) do
    Class.new(MongoModel) do
      attribute :_id, Integer
      attribute :one, String
      attribute :two, Integer
    end
  end

  before { stub_const('Models::Test', model) }

  let(:repository_instance) { repository.new(mongo_client) }
  let(:collection) { repository_instance.collection }
  let(:records) do
    Array.new(5) { |i| model.new(_id: i, one: 'test', two: i + 10) }
  end

  let(:non_existing_record) { model.new(_id: 5, one: 'test', two: 15) }

  describe '#find' do
    it 'returns no results when the collection is empty' do
      expect(repository_instance.find({}).count).to eq(0)
    end

    it 'returns the correct amount of results for a non-empty collection' do
      records.each(&collection.method(:insert_one))
      expect(repository_instance.find({}).count).to eq(5)
    end

    it 'assigns correct attributes to the returned records' do
      inserted_record = model.new(_id: 1, one: 'test', two: 2)
      collection.insert_one(inserted_record)
      found_model = repository_instance.find({}).first
      expect(found_model).to eq(inserted_record)
    end

    it 'queries the database correctly' do
      records.each(&collection.method(:insert_one))
      expect(repository_instance.find(_id: records.first._id).first).to eq(
        records.first
      )
    end
  end

  describe '#find_one' do
    before { records.each(&collection.method(:insert_one)) }

    it 'raises DocumentNotFoundError if no document matches the query' do
      expect { repository_instance.find_one(_id: non_existing_record.id) }.to(
        raise_error(Repository::DocumentNotFoundError)
      )
    end

    it 'returns a single model instance' do
      result = repository_instance.find_one(_id: records.sample.id)
      expect(result).to be_instance_of(model)
    end
  end

  describe '#insert' do
    it 'persists the correct amount of documents' do
      records.each(&repository_instance.method(:insert))
      expect(collection.find({}).count).to eq(5)
    end

    it 'persists the correct attributes' do
      inserted_record = model.new(_id: 1, one: 'test', two: 2)
      repository_instance.insert(inserted_record)
      hash = collection.find.first.deep_symbolize_keys
      expect(model.new(hash)).to eq(inserted_record)
    end

    # we need this as insurance, since mongodb keeps changing error codes
    # @see https://github.com/mongodb/mongo-ruby-driver/blob/master/lib/mongo/error/operation_failure.rb#L23-L26
    it 'raises DocumentExistsError if document already exists' do
      inserted_record = model.new(_id: 1, one: 'test', two: 2)
      repository_instance.insert(inserted_record)
      expect { repository_instance.insert(inserted_record) }.to raise_error(
        Repository::DocumentExistsError
      )
    end
  end

  describe '#update' do
    before { records.each(&collection.method(:insert_one)) }
    let(:updated_record) { records.sample }

    it 'updates the correct document in the database' do
      updated_record.attributes = { one: 'updated' }
      repository_instance.update(updated_record)
      hash = collection.find(_id: updated_record.id).first.deep_symbolize_keys
      expect(model.new(hash)).to eq(updated_record)
    end

    it 'raises DocumentNotFoundError if trying to update non-existing model' do
      expect { repository_instance.update(non_existing_record) }.to raise_error(
        Repository::DocumentNotFoundError
      )
    end
  end

  describe '#delete' do
    before { records.each(&collection.method(:insert_one)) }

    it 'deletes the correct amount of documents from the database' do
      repository_instance.delete(records.first)
      expect(collection.find.count).to eq(4)
    end

    it 'deletes the correct document from the database' do
      repository_instance.delete(records.first)
      expect(collection.find(_id: records.first.id).count).to eq(0)
    end

    it 'raises DocumentNotFoundError if trying to delete non-existing model' do
      expect { repository_instance.update(non_existing_record) }.to raise_error(
        Repository::DocumentNotFoundError
      )
    end
  end
end
