# frozen_string_literal: true
require 'spec_helper'

describe RepositoryPattern do
  it 'has a version number' do
    expect(RepositoryPattern::VERSION).not_to be nil
  end

  describe '.models_namespace' do
    before do
      described_class.instance_variable_set(:@models_namespace, nil)
      stub_const('TestModelsNamespace', Module.new)
    end

    it 'can be used to set the models namespace' do
      described_class.models_namespace TestModelsNamespace
      expect(described_class.instance_variable_get(:@models_namespace)).to be(
        TestModelsNamespace
      )
    end

    it 'can be used to get the models namespace' do
      described_class.instance_variable_set(
        :@models_namespace,
        TestModelsNamespace
      )
      expect(described_class.models_namespace).to be(TestModelsNamespace)
    end

    it 'raises an exception if trying to read it when it is unset' do
      described_class.instance_variable_set(:@models_namespace, nil)
      expect { described_class.models_namespace }.to raise_error(
        ConfigurationError
      )
    end
  end
end
