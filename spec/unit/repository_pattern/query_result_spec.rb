# frozen_string_literal: true
require 'spec_helper'
require 'mongo'
require 'repository_pattern/query_result'

describe QueryResult do
  let(:cursor) { instance_double(Mongo::Collection::View) }
  let(:model_class) { Class.new }
  let(:query_result_instance) { described_class.new(cursor, model_class) }

  it 'is enumerable' do
    expect(query_result_instance).to be_a(Enumerable)
  end

  described_class::DELEGATED_METHODS.each do |method|
    context method.to_s do
      before { allow(cursor).to receive(method) }

      it 'is delegated to the given cursor' do
        query_result_instance.public_send(method, :param)
        expect(cursor).to have_received(method).with(:param)
      end

      it 'returns self' do
        result = query_result_instance.public_send(method, :param)
        expect(result).to be(query_result_instance)
      end
    end
  end

  context 'each' do
    it 'returns a enumerator' do
      expect(query_result_instance.each).to be_a(Enumerator)
    end
    it 'wraps results from underlying cursor with the model class' do
      allow(cursor).to receive(:each).and_yield(test: 1)
      allow(model_class).to receive(:new).with(Hash)
      query_result_instance.each.to_a
      expect(model_class).to have_received(:new).with(test: 1)
    end

    it 'is lazy' do
      allow(cursor).to receive(:each).and_yield(test: 1).and_yield(test: 2)
      allow(model_class).to receive(:new).with(Hash)
      query_result_instance.each.first
      expect(model_class).to have_received(:new).once
    end
  end
end
