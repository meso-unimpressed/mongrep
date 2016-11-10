# frozen_string_literal: true
require 'spec_helper'
require 'mongrep/core_ext/hash'

describe Hash do
  context '#slice_with_dot_notation' do
    let(:instance) { { test: 1, foo: 2, 'bar' => 3, foobar: { foo: 'bar' } } }

    it "returns a #{described_class}" do
      expect(instance.slice_with_dot_notation(:test)).to be_a(described_class)
    end

    it 'includes only the given keys' do
      expect(instance.slice_with_dot_notation(:test, :foo)).to eq(
        'test' => 1, 'foo' => 2
      )
    end

    it 'can access nested values' do
      expect(instance.slice_with_dot_notation('foobar.foo')).to eq(
        'foobar.foo' => 'bar'
      )
    end

    it 'raises an error when trying to access an invalid path' do
      expect { instance.slice_with_dot_notation('foo.bar') }.to raise_error(
        NoMethodError, /`key\?'/
      )
    end

    it 'stringifies keys' do
      expect(instance.slice_with_dot_notation(:bar)).to eq('bar' => 3)
    end

    it 'stringifies nested keys' do
      expect(instance.slice_with_dot_notation('foobar.foo')).to eq(
        'foobar.foo' => 'bar'
      )
    end
  end
end
