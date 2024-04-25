# frozen_string_literal: true

require 'aliyun/oss'

RSpec.describe 'Aliyun OSS' do
  let(:object_key) { 'hello.txt' }

  context '公开读写' do
    let(:bucket) do
      client = Aliyun::OSS::Client.new(
        endpoint: 'https://oss-cn-shanghai.aliyuncs.com',
        access_key_id: 'XXX',
        access_key_secret: 'XXX'
      )
      client.get_bucket('hefei-dev')
    end

    it "存储和获取对象" do
      bucket.delete_object(object_key) if bucket.object_exists?(object_key)
      bucket.put_object(object_key){ |stream| stream << 'Hello, OSS!'.dup }

      bucket.get_object(object_key){ |content| expect(content).to eq 'Hello, OSS!' }
    end

    it '返回对象的 URL（不签名）' do
      bucket.delete_object(object_key) if bucket.object_exists?(object_key)
      bucket.put_object(object_key){ |stream| stream << 'Hello, OSS!'.dup }

      url = bucket.object_url(object_key, false)
      expect(url).to eq('https://hefei-dev.oss-cn-shanghai.aliyuncs.com/hello.txt')
    end

    it '上传对象后使用链接访问' do
      bucket.delete_object(object_key) if bucket.object_exists?(object_key)
      bucket.put_object(object_key){ |stream| stream << 'Hello, OSS!'.dup }

      url = 'https://hefei-dev.oss-cn-shanghai.aliyuncs.com/hello-oss.txt'
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      expect(response).to be_a(Net::HTTPSuccess)
      expect(response.body).to eq('Hello, OSS!')
    end

    it "设置对象的元数据" do
      bucket.delete_object(object_key) if bucket.object_exists?(object_key)
      bucket.put_object(object_key, metas: { a: 1 }){ |stream| stream << 'Hello, OSS!'.dup }

      object = bucket.get_object(object_key)
      expect(object.metas).to eq({ 'a' => '1' })
    end
  end

  context '私有读写' do
    let(:bucket) do
      client = Aliyun::OSS::Client.new(
        endpoint: 'https://oss-cn-shanghai.aliyuncs.com',
        access_key_id: 'XXX',
        access_key_secret: 'XXX'
      )
      client.get_bucket('mkj-private')
    end

    it "存储和获取对象" do
      bucket.delete_object(object_key) if bucket.object_exists?(object_key)
      bucket.put_object(object_key){ |stream| stream << 'Hello, OSS!'.dup }

      bucket.get_object(object_key){ |content| expect(content).to eq 'Hello, OSS!' }
    end

    it '上传对象后直接使用链接访问会报错' do
      bucket.delete_object(object_key) if bucket.object_exists?(object_key)
      bucket.put_object(object_key){ |stream| stream << 'Hello, OSS!'.dup }

      url = 'https://mkj-private.oss-cn-shanghai.aliyuncs.com/hello-oss.txt'
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      expect(response).to be_a(Net::HTTPForbidden)
      # puts response.body
    end

    it '上传对象后使用签名链接访问' do
      bucket.delete_object(object_key) if bucket.object_exists?(object_key)
      bucket.put_object(object_key){ |stream| stream << 'Hello, OSS!'.dup }

      url = bucket.object_url(object_key, true, 60)
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      expect(response).to be_a(Net::HTTPSuccess)
      expect(response.body).to eq('Hello, OSS!')
    end
  end
end
