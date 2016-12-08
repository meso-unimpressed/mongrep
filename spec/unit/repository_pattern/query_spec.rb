# frozen_string_literal: true
require 'spec_helper'
require 'mongrep/query'

describe Query do
  context '.new' do
    it 'takes an optional query hash and assigns it to be accessible by to_h' do
      expect(described_class.new(test: 1).to_h).to eq(test: 1)
    end
  end

  context '#&' do
    let(:first) { described_class.new(foo: 1, bar: 2) }
    let(:second) { described_class.new(foo: 2) }

    it 'returns a query' do
      expect(first & second).to be_a(described_class)
    end

    it 'merges two queries' do
      expect((first & second).to_h).to eq(foo: 2, bar: 2)
    end

    it 'does not modify the query' do
      _ = first & second
      expect(first.to_h).to eq(foo: 1, bar: 2)
    end

    it 'does not modify the other query' do
      _ = first & second
      expect(second.to_h).to eq(foo: 2)
    end
  end

  context '#|' do
    let(:first) { described_class.new(foo: 1) }
    let(:second) { described_class.new(foo: 2) }

    it 'returns a query' do
      expect(first | second).to be_a(described_class)
    end

    it 'merges two queries' do
      expect((first | second).to_h).to eq(:$or => [{ foo: 1 }, { foo: 2 }])
    end

    it 'does not modify the query' do
      _ = first | second
      expect(first.to_h).to eq(foo: 1)
    end

    it 'does not modify the other query' do
      _ = first | second
      expect(second.to_h).to eq(foo: 2)
    end
  end

  context '#where' do
    let(:query) { described_class.new(foo: 1, bar: 2) }

    it 'returns a query' do
      expect(query.where({})).to be_a(described_class)
    end

    it 'merges the given query to the query hash' do
      expect(query.where(foo: 2).to_h).to eq(foo: 2, bar: 2)
    end

    it 'does not modify the query' do
      _ = query.where(foo: 2)
      expect(query.to_h).to eq(foo: 1, bar: 2)
    end
  end

  context '#or' do
    let(:query) { described_class.new(foo: 1) }

    it 'returns a query' do
      expect(query.or({})).to be_a(described_class)
    end

    it 'merges the given query to the query hash' do
      expect(query.or(foo: 2).to_h).to eq(:$or => [{ foo: 1 }, { foo: 2 }])
    end

    it 'does not modify the query' do
      _ = query.or(foo: 2)
      expect(query.to_h).to eq(foo: 1)
    end
  end

  context '#and' do
    let(:query) { described_class.new(foo: { bar: 1 }) }

    it 'returns a query' do
      expect(query.and({})).to be_a(described_class)
    end

    it 'merges the given query to the query hash' do
      expect(query.and(foo: { foo: 2 }).to_h).to eq(
        :$and => [{ foo: { bar: 1 } }, { foo: { foo: 2 } }]
      )
    end

    it 'does not modify the query' do
      _ = query.and(foo: 2)
      expect(query.to_h).to eq(foo: { bar: 1 })
    end
  end
end
