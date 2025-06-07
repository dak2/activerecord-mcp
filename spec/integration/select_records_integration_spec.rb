require 'spec_helper'

RSpec.describe 'SelectRecords Integration', :integration do
  let(:tool) { ActiveRecordMcp::Tools::SelectRecords.new }

  before do
    ActiveRecordMcp::Config.setup do |config|
      config.projects_root_file_path = '/tmp/test_rails_project'
    end
  end

  describe 'tool configuration' do
    it 'uses the configured project path' do
      expect(tool.send(:projects_root_file_path)).to eq('/tmp/test_rails_project')
    end
  end

  describe 'query building examples' do
    it 'generates correct query for "show posts that has content"' do
      query = tool.send(:build_query_chain, 'Post', 'content IS NOT NULL', nil, nil, false)
      expect(query).to eq('Post.all.where("content IS NOT NULL")')
    end

    it 'generates correct query for "show posts sorted by date of posting"' do
      query = tool.send(:build_query_chain, 'Post', nil, 'created_at DESC', nil, false)
      expect(query).to eq('Post.all.order("created_at DESC")')
    end

    it 'generates correct query for "show 5 posts"' do
      query = tool.send(:build_query_chain, 'Post', nil, nil, 5, false)
      expect(query).to eq('Post.all.limit(5)')
    end

    it 'generates correct query for "show the size of posts"' do
      query = tool.send(:build_query_chain, 'Post', nil, nil, nil, true)
      expect(query).to eq('Post.all.count')
    end

    it 'generates complex query combining all features' do
      query = tool.send(:build_query_chain, 
        'Post', 
        'status = "published" AND content IS NOT NULL', 
        'created_at DESC', 
        5, 
        false
      )
      expect(query).to eq('Post.all.where("status = "published" AND content IS NOT NULL").order("created_at DESC").limit(5)')
    end
  end

  describe 'error handling' do
    it 'provides helpful error message for missing model name' do
      expect {
        tool.call
      }.to raise_error(/Model name is required/)
    end
  end
end