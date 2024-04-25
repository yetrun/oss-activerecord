# frozen_string_literal: true

require 'oss/adapters/aliyun_adapter'
require 'oss/adapters/qiniu_adapter'

RSpec.describe OSS::Adapters do
  shared_examples 'an adapter' do
    let(:object_key) { 'hello.txt' }
    let(:filepath) { Pathname.new(__dir__).join('../fixtures/hello.txt').to_s }

    it 'uploads file' do
      expect {
        oss_adapter.upload(filepath, object_key)
      }.not_to raise_error
    end

    it 'returns signed url' do
      url = oss_adapter.signed_url(object_key)
      expect(url).to start_with(endpoint)
      expect(url).to include('?')
    end
  end

  describe OSS::Adapters::AliyunAdapter do
    let(:endpoint) { 'https://mkj-private.oss-cn-shanghai.aliyuncs.com' }
    let(:oss_adapter) do
      OSS::Adapters::AliyunAdapter.new(
        endpoint: 'https://oss-cn-shanghai.aliyuncs.com',
        access_key: 'XXX',
        secret_key: 'XXX',
        bucket: 'mkj-private'
      )
    end

    include_examples 'an adapter'
  end

  describe OSS::Adapters::QiniuAdapter do
    let(:endpoint) { 'http://scjo0i44d.hn-bkt.clouddn.com' }
    let(:oss_adapter) do
      OSS::Adapters::QiniuAdapter.new(
        endpoint: 'http://scjo0i44d.hn-bkt.clouddn.com',
        access_key: 'XXX',
        secret_key: 'XXX',
        bucket: 'maikeji-private'
      )
    end

    include_examples 'an adapter'
  end
end
