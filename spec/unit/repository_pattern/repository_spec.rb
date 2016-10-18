# frozen_string_literal: true
require 'spec_helper'
require 'mongo'

require 'repository_pattern/repository'
require 'repository_pattern/mongo_model'
require 'repository_pattern/query'
require 'repository_pattern/query_result'

describe Repository do
  let(:collection) do
    instance_double(Mongo::Collection, insert_one: true, aggregate: true)
  end

  let(:database) { instance_double(Mongo::Database, :[] => collection) }

  let(:model) do
    Class.new(MongoModel) do
      attribute :_id, Integer
    end
  end

  let(:record) { model.new(_id: 1) }

  let(:repository) do
    Class.new(described_class) do
      define_singleton_method(:name) { 'Tests' }
    end
  end

  let(:repository_instance) { repository.new(database) }

  before do
    stub_const('Models::Test', model)
    RepositoryPattern.models_namespace Models
  end

  describe '.new' do
    it 'initializes a collection with the correct collection name' do
      repository.new(database)
      expect(database).to have_received(:[]).with('tests')
    end
  end

  describe '#collection_name' do
    it 'derives it from its class name' do
      expect(repository_instance.collection_name).to eq('tests')
    end
  end

  describe '#model_class' do
    it 'returns the expected class' do
      expect(repository_instance.model_class).to eq(Models::Test)
    end
  end

  describe '#collection' do
    it 'is set upon instantiation' do
      expect(repository_instance.collection).to be(collection)
    end
  end

  describe '#find' do
    let(:collection_view) do
      instance_double(Mongo::Collection::View).tap do |view|
        allow(view).to receive(:aggregate).and_return(view)
      end
    end

    before do
      allow(collection).to receive(:find).and_return(collection_view)
    end

    it 'creates a query object out of a given hash' do
      allow(Query).to receive(:new).and_call_original
      repository_instance.find(test: 1)
      expect(Query).to have_received(:new).with(test: 1)
    end

    it 'yields a query object if called without arguments' do
      repository_instance.find do |query|
        expect(query).to be_a(Query)
        query
      end
    end

    it 'yields the initial query as a query object if passed a block' do
      repository_instance.find(test: 1) do |yielded_query|
        expect(yielded_query.to_h).to eq(test: 1)
        yielded_query
      end
    end

    it 'raises an argument error if given a bogous query' do
      expect { repository_instance.find(:invalid_query) }.to raise_error(
        ArgumentError
      )
    end

    it 'returns a query result' do
      expect(repository_instance.find(test: 1)).to be_a(QueryResult)
    end
  end

  describe '#find_one' do
    it 'calls first on the result of #find' do
      result = instance_double(QueryResult, first: :something)
      allow(repository_instance).to receive(:find).and_return(result)
      repository_instance.find_one(test: 1)
      expect(result).to have_received(:first)
    end

    it 'raises a DocumentNotFoundError if the result is empty' do
      result = instance_double(QueryResult, first: nil)
      allow(repository_instance).to receive(:find).and_return(result)
      expect { repository_instance.find_one(test: 1) }.to raise_error(
        Repository::DocumentNotFoundError
      )
    end
  end

  let(:write_result_document) { { 'n' => 1 } }

  before do
    allow(record).to receive(:to_h).and_return(_id: 1, test: 2, foo: :bar)
  end

  describe '#insert' do
    let(:write_result) do
      instance_double(Mongo::Operation::Write::Insert::Result).tap do |result|
        allow(result).to receive(:documents).and_return([write_result_document])
      end
    end

    before do
      allow(collection).to receive(:insert_one).and_return(write_result)
    end

    it 'passes the record hash to collection#insert_one' do
      repository_instance.insert(record)
      expect(collection).to have_received(:insert_one).with(record.to_h)
    end

    it 'raises an error if the record already exists in the database' do
      duplicate_key_error = Mongo::Error::OperationFailure.new('E11000')
      allow(collection).to receive(:insert_one).and_raise(duplicate_key_error)
      expect { repository_instance.insert(record) }.to raise_error(
        Repository::DocumentExistsError
      )
    end

    it 'doesnt eat non-E11000 operation failure errors' do
      unspecified_error = Mongo::Error::OperationFailure.new('E11111')
      allow(collection).to receive(:insert_one).and_raise(unspecified_error)
      expect { repository_instance.insert(record) }.to raise_error(
        unspecified_error
      )
    end
  end

  describe '#update' do
    let(:write_result) do
      instance_double(Mongo::Operation::Write::Update::Result).tap do |result|
        allow(result).to receive(:documents).and_return([write_result_document])
      end
    end

    before do
      allow(collection).to receive(:update_one).and_return(write_result)
    end

    it 'uses the record _id as query and replaces the rest of the fields' do
      repository_instance.update(record)
      expect(collection).to have_received(:update_one).with(
        { _id: 1 }, test: 2, foo: :bar
      )
    end

    it 'raises UnpersistedModelError if the record has no value for _id' do
      allow(record).to receive(:_id).and_return(nil)
      expect { repository_instance.update(record) }.to raise_error(
        Repository::UnpersistedModelError
      )
    end

    it 'uses $set with a subset of the record hash defined by field names' do
      repository_instance.update(record, fields: [:test])
      expect(collection).to have_received(:update_one).with(
        { _id: 1 }, :$set => { 'test' => 2 }
      )
    end

    it 'raises DocumentNotFoundError if no documents were deleted by the db' do
      allow(write_result).to receive(:documents).and_return([{ 'n' => 0 }])
      expect { repository_instance.update(record) }.to raise_error(
        Repository::DocumentNotFoundError
      )
    end
  end

  describe '#delete' do
    let(:write_result) do
      instance_double(Mongo::Operation::Write::Delete::Result).tap do |result|
        allow(result).to receive(:documents).and_return([write_result_document])
      end
    end

    before do
      allow(collection).to receive(:delete_one).and_return(write_result)
    end

    it 'calls delete_one on the collection' do
      repository_instance.delete(record)
      expect(collection).to have_received(:delete_one).with(_id: 1)
    end

    it 'raises an error if the record has no value for _id' do
      allow(record).to receive(:_id).and_return(nil)
      expect { repository_instance.delete(record) }.to raise_error(
        Repository::UnpersistedModelError
      )
    end

    it 'raises DocumentNotFoundError if no documents were deleted by the db' do
      allow(write_result).to receive(:documents).and_return([{ 'n' => 0 }])
      expect { repository_instance.delete(record) }.to raise_error(
        Repository::DocumentNotFoundError
      )
    end
  end
end
