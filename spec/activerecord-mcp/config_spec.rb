# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecordMcp::Config do
  describe '.instance' do
    it 'returns a singleton instance' do
      instance1 = described_class.instance
      instance2 = described_class.instance
      expect(instance1).to be(instance2)
    end
  end

  describe '.setup' do
    it 'yields the instance for configuration' do
      expect { |b| described_class.setup(&b) }.to yield_with_args(described_class.instance)
    end

    it 'allows configuration of projects_root_file_path' do
      test_path = '/test/path'
      described_class.setup do |config|
        config.projects_root_file_path = test_path
      end
      expect(described_class.instance.projects_root_file_path).to eq(test_path)
    end
  end

  describe '#initialize' do
    let(:config) { described_class.new }

    it 'sets default projects_root_file_path to current directory' do
      expect(config.projects_root_file_path).to eq(Dir.pwd)
    end

    it 'sets default projects_models_file_path' do
      expect(config.projects_models_file_path).to eq('app/models')
    end

    it 'sets default projects_db_file_path' do
      expect(config.projects_db_file_path).to eq('db')
    end
  end

  describe 'attribute accessors' do
    let(:config) { described_class.instance }

    it 'allows getting and setting projects_root_file_path' do
      test_path = '/custom/root/path'
      config.projects_root_file_path = test_path
      expect(config.projects_root_file_path).to eq(test_path)
    end

    it 'allows getting and setting projects_models_file_path' do
      test_path = 'custom/models'
      config.projects_models_file_path = test_path
      expect(config.projects_models_file_path).to eq(test_path)
    end

    it 'allows getting and setting projects_db_file_path' do
      test_path = 'custom/db'
      config.projects_db_file_path = test_path
      expect(config.projects_db_file_path).to eq(test_path)
    end
  end
end
