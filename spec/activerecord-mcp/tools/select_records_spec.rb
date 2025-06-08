require 'spec_helper'

RSpec.describe ActiveRecordMcp::Tools::SelectRecords do
  let(:tool) { described_class.new }
  let(:test_dir) { '/test/rails/project' }

  before do
    ActiveRecordMcp::Config.setup do |config|
      config.projects_root_file_path = test_dir
    end
  end

  describe '.projects_root_file_path' do
    it 'returns the configured path from Config' do
      expect(described_class.send(:projects_root_file_path)).to eq(test_dir)
    end
  end

  describe '.classify' do
    it 'converts table names to class names' do
      expect(described_class.send(:classify, 'users')).to eq('User')
      expect(described_class.send(:classify, 'blog_posts')).to eq('BlogPost')
      expect(described_class.send(:classify, 'posts')).to eq('Post')
    end
  end

  describe '.build_query_chain' do
    it 'builds basic query without conditions' do
      query = described_class.send(:build_query_chain, 'Post', nil, nil, nil, false)
      expect(query).to eq('Post.all')
    end

    it 'builds query with filter condition' do
      query = described_class.send(:build_query_chain, 'Post', 'title IS NOT NULL', nil, nil, false)
      expect(query).to eq('Post.all.where("title IS NOT NULL")')
    end

    it 'builds query with order clause' do
      query = described_class.send(:build_query_chain, 'Post', nil, 'created_at DESC', nil, false)
      expect(query).to eq('Post.all.order("created_at DESC")')
    end

    it 'builds query with limit' do
      query = described_class.send(:build_query_chain, 'Post', nil, nil, 5, false)
      expect(query).to eq('Post.all.limit(5)')
    end

    it 'builds query with all conditions' do
      query = described_class.send(:build_query_chain, 'Post', 'status = "published"', 'created_at DESC', 10, false)
      expect(query).to eq('Post.all.where("status = "published"").order("created_at DESC").limit(10)')
    end

    it 'builds count query' do
      query = described_class.send(:build_query_chain, 'Post', nil, nil, nil, true)
      expect(query).to eq('Post.all.count')
    end

    it 'builds count query with filter condition' do
      query = described_class.send(:build_query_chain, 'Post', 'status = "published"', nil, nil, true)
      expect(query).to eq('Post.all.where("status = "published"").count')
    end

    it 'ignores order and limit for count queries' do
      query = described_class.send(:build_query_chain, 'Post', 'status = "published"', 'created_at DESC', 5, true)
      expect(query).to eq('Post.all.where("status = "published"").count')
    end
  end

  describe '#capture3_args_for' do
    it 'raises error when model_name is nil' do
      expect {
        described_class.send(:capture3_args_for, model_name: nil)
      }.to raise_error(/Model name is required/)
    end

    it 'builds ruby command for basic query' do
      args = described_class.send(:capture3_args_for, model_name: 'posts')
      expect(args[0]).to eq('ruby')
      expect(args[1]).to eq('-e')
      expect(args[2]).to include('Post.all.inspect')
      expect(args[3][:chdir]).to eq(test_dir)
    end

    it 'builds ruby command for count query' do
      args = described_class.send(:capture3_args_for, model_name: 'posts', count_only: true)
      expect(args[2]).to include('Post.all.count')
      expect(args[2]).not_to include('.inspect')
    end

    it 'builds ruby command with all parameters' do
      args = described_class.send(:capture3_args_for, 
        model_name: 'posts',
        filter_condition: 'status = "published"',
        order_by: 'created_at DESC',
        limit: 5
      )
      expected_query = 'Post.all.where("status = "published"").order("created_at DESC").limit(5)'
      expect(args[2]).to include(expected_query)
    end
  end

  describe '#call' do
    before do
      allow(Open3).to receive(:capture3).and_return(['mock output', '', double(success?: true)])
    end

    it 'calls Open3.capture3 with correct arguments' do
      expect(Open3).to receive(:capture3).with(
        'ruby',
        '-e',
        /Post\.all\.inspect/,
        { chdir: test_dir }
      )
      
      described_class.call(model_name: 'posts', server_context: {})
    end

    it 'returns stdout when successful' do
      allow(Open3).to receive(:capture3).and_return(['success output', 'error', double(success?: true)])
      result = described_class.call(model_name: 'posts', server_context: {})
      expect(result).to be_a(MCP::Tool::Response)
      expect(result.content).to eq([{ type: "text", text: "success output" }])
    end

    it 'returns stderr when failed' do
      allow(Open3).to receive(:capture3).and_return(['output', 'error message', double(success?: false)])
      result = described_class.call(model_name: 'posts', server_context: {})
      expect(result).to be_a(MCP::Tool::Response)
      expect(result.content).to eq([{ type: "text", text: "error message" }])
    end

    it 'handles all parameters correctly' do
      expect(Open3).to receive(:capture3).with(
        'ruby',
        '-e',
        /Post\.all\.where.*order.*limit/,
        { chdir: test_dir }
      )
      
      described_class.call(
        model_name: 'posts',
        filter_condition: 'published = true',
        order_by: 'created_at DESC',
        limit: 10,
        server_context: {}
      )
    end

    it 'handles count_only parameter' do
      expect(Open3).to receive(:capture3).with(
        'ruby',
        '-e',
        /Post\.all\.count/,
        { chdir: test_dir }
      )
      
      described_class.call(model_name: 'posts', count_only: true, server_context: {})
    end
  end
end