# frozen_string_literal: true
require 'spec_helper'

require 'repository_pattern/repository'
require 'repository_pattern/read_only_repository'

describe ReadOnlyRepository do
  let(:repository_instance) { Class.new { include ReadOnlyRepository }.new }

  %i(insert update delete).each do |method|
    describe "##{method}" do
      it 'raises an error' do
        expect { repository_instance.public_send(method) }.to raise_error(
          ReadOnlyRepository::WriteError
        )
      end
    end
  end
end
