# frozen_string_literal: true
require 'spec_helper'

require 'active_support/core_ext/hash/slice'
require 'mongrep/model'

describe Model do
  let(:sub_model_class) do
    Class.new do
      include(Model)

      attribute :foo, String
      attribute :bar, String
    end
  end

  let(:model_class) do
    Class.new do
      include(Model)

      attribute :foobar, SubModelClass
      attribute :foobar_array, Array[SubModelClass]
      attribute :foobar_hash, Hash[Symbol, SubModelClass]
    end
  end

  before do
    stub_const('SubModelClass', sub_model_class)
  end

  let(:model_instance) do
    model_class.new(
      foobar: sub_model_class.new(foo: 'foo', bar: 'bar'),
      foobar_array: Array.new(3) do |i|
        sub_model_class.new(foo: "foo_#{i}", bar: "bar_#{i}")
      end,
      foobar_hash: {
        foo: sub_model_class.new(foo: 'foo_foo', bar: 'bar_foo'),
        bar: sub_model_class.new(foo: 'foo_bar', bar: 'bar_bar')
      }
    )
  end

  describe '#to_h' do
    it 'returns a hash' do
      expect(model_instance.to_h).to be_a(Hash)
    end

    it 'converts any sub models into hashes' do
      expect(model_instance.to_h[:foobar]).to be_a(Hash)
    end

    it 'converts any sub model items in arrays into hashes' do
      model_instance.to_h[:foobar_array].each do |foobar|
        expect(foobar).to be_a(Hash)
      end
    end

    it 'converts any sub model values in hashes into hashes' do
      model_instance.to_h[:foobar_hash].values.each do |foobar|
        expect(foobar).to be_a(Hash)
      end
    end
  end

  it 'does strict coercion' do
    expect { sub_model_class.new(foo: 'test', bar: nil) }.to raise_error(
      Virtus::CoercionError
    )
  end

  describe '.partial' do
    let(:partial_class) { sub_model_class.partial(:foo) }
    let(:nested_hash) do
      {
        foobar: { foo: 'test' },
        foobar_array: [{ bar: 'test' }],
        foobar_hash: { test: { foo: 'test' } }
      }
    end
    let(:simple_hash) { { foo: 'test' } }

    it 'returns a class' do
      expect(model_class.partial(:foobar)).to be_a(Class)
    end

    it 'only contains given attributes' do
      partial = partial_class.new(simple_hash)
      expect(partial.attributes).to eq(simple_hash)
    end

    it 'still coerces arguments' do
      expect { partial_class.new(foo: Class.new) }.to raise_error(
        Virtus::CoercionError
      )
    end

    it 'supports nesting' do
      partial_class = model_class.partial(
        foobar: [:foo], foobar_array: [:bar], foobar_hash: [:foo]
      )
      partial = partial_class.new(nested_hash)
      expect(partial.to_h).to eq(nested_hash)
    end

    it 'has a human readable representation through #inspect' do
      result = partial_class.new(simple_hash).inspect
      expect(result).to match(
        /#<SubModelClass::Partial\[:foo\]:[0-9a-f]+ @foo="test">/
      )
    end
  end
end
