# frozen_string_literal: true
require 'spec_helper'
require 'mongo'
require 'repository_pattern/query_result'

describe QueryResult do
  let(:collection_view) { instance_double(Mongo::Collection::View) }
  let(:model_class) { Class.new }
  let(:query_result_instance) do
    described_class.new(collection_view, model_class)
  end

  it 'is enumerable' do
    expect(query_result_instance).to be_a(Enumerable)
  end

  described_class::DELEGATED_METHODS.each do |method|
    context method.to_s do
      context 'with normal collection view' do
        before { allow(collection_view).to receive(method) }

        it 'is delegated to the given collection_view' do
          query_result_instance.public_send(method, :param)
          expect(collection_view).to have_received(method).with(:param)
        end

        it 'returns self' do
          result = query_result_instance.public_send(method, :param)
          expect(result).to be(query_result_instance)
        end
      end

      context 'with aggregation as collection view' do
        let(:pipeline) { [{ test: 'foo' }] }
        let(:collection_view) do
          instance_double(
            Mongo::Collection::View::Aggregation, pipeline: pipeline
          )
        end

        before do
          allow(collection_view).to receive(:is_a?).with(
            Mongo::Collection::View::Aggregation
          ).and_return(true)
        end

        it 'adds it to the pipeline' do
          query_result_instance.public_send(method, :param)
          stage = method == :projection ? :project : method
          expect(pipeline).to eq([{ test: 'foo' }, { "$#{stage}": :param }])
        end
      end
    end
  end

  context 'each' do
    before do
      allow(collection_view).to(
        receive(:each).and_yield(test: 1).and_yield(test: 2)
      )
    end

    it 'returns a enumerator' do
      expect(query_result_instance.each).to be_a(Enumerator)
    end

    it 'wraps results from underlying collection_view with the model class' do
      allow(model_class).to receive(:new).with(Hash)
      query_result_instance.each.to_a
      expect(model_class).to have_received(:new).with(test: 1)
    end

    it 'is lazy' do
      allow(model_class).to receive(:new).with(Hash)
      query_result_instance.each.first
      expect(model_class).to have_received(:new).once
    end
  end
end
