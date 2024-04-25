# frozen_string_literal: true

require 'qiniu'

RSpec.describe 'Qiniu OSS' do
  before(:context) do
    Qiniu.establish_connection! access_key: 'XXX',
                                secret_key: 'XXX'
  end

  let(:object_key) { 'hello.txt' }
  let(:filepath) { Pathname.new(__dir__).join('../fixtures/hello.txt').to_s }

  context '公开读写' do
    let(:bucket) { 'maikeji-public' }

    it "上传对象" do
      # 构建上传策略，上传策略的更多参数请参照 http://developer.qiniu.com/article/developer/security/put-policy.html
      put_policy = Qiniu::Auth::PutPolicy.new(
        bucket, # 存储空间
        object_key,    # 指定上传的资源名，如果传入 nil，就表示不指定资源名，将使用默认的资源名
        3600    # token 过期时间，默认为 3600 秒，即 1 小时
      )
      # 生成上传 Token
      uptoken = Qiniu::Auth.generate_uptoken(put_policy)
      # 要上传文件的本地路径
      filePath = filepath
      # 调用 upload_with_token_2 方法上传
      code, result, response_headers = Qiniu::Storage.upload_with_token_2(
        uptoken,
        filePath,
        object_key,
        nil, # 可以接受一个 Hash 作为自定义变量，请参照 http://developer.qiniu.com/article/kodo/kodo-developer/up/vars.html#xvar
        bucket: bucket
      )
      expect(code).to eq(200)
      expect(result['key']).to eq(object_key)
      expect(result).to have_key('hash')
    end

    it '返回对象的签名 URL' do
      primitive_url = 'http://scjl5xnma.hn-bkt.clouddn.com/hello.txt'
      download_url = Qiniu::Auth.authorize_download_url(primitive_url)
      expect(download_url).to start_with('http://scjl5xnma.hn-bkt.clouddn.com/hello.txt?e=')
    end

    it '上传对象后使用链接访问' do
      url = 'http://scjl5xnma.hn-bkt.clouddn.com/hello.txt'
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      expect(response).to be_a(Net::HTTPSuccess)
      expect(response.body).to eq('Hello, OSS!')
    end

    it '返回资源的元信息' do
      code, result, response_headers = Qiniu::Storage.stat(
        bucket,     # 存储空间
        object_key         # 资源名
      )
      expect(code).to eq(200)
      expect(result['mimeType']).to eq('text/plain')
    end

    # skip "设置对象的元数据"
  end

  context '私有读写' do
    let(:bucket) { 'maikeji-private' }

    it "上传对象" do
      # 构建上传策略，上传策略的更多参数请参照 http://developer.qiniu.com/article/developer/security/put-policy.html
      put_policy = Qiniu::Auth::PutPolicy.new(
        bucket, # 存储空间
        object_key,    # 指定上传的资源名，如果传入 nil，就表示不指定资源名，将使用默认的资源名
        3600    # token 过期时间，默认为 3600 秒，即 1 小时
      )
      # 生成上传 Token
      uptoken = Qiniu::Auth.generate_uptoken(put_policy)
      # 要上传文件的本地路径
      filePath = filepath
      # 调用 upload_with_token_2 方法上传
      code, result, response_headers = Qiniu::Storage.upload_with_token_2(
        uptoken,
        filePath,
        object_key,
        nil, # 可以接受一个 Hash 作为自定义变量，请参照 http://developer.qiniu.com/article/kodo/kodo-developer/up/vars.html#xvar
        bucket: bucket
      )
      expect(code).to eq(200)
      expect(result['key']).to eq(object_key)
      expect(result).to have_key('hash')
    end

    it '上传对象后直接使用链接访问会报错' do
      url = 'http://scjo0i44d.hn-bkt.clouddn.com/hello.txt'
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      expect(response).to be_a(Net::HTTPUnauthorized)
    end

    it '上传对象后使用签名链接访问' do
      primitive_url = 'http://scjo0i44d.hn-bkt.clouddn.com/hello.txt'
      download_url = Qiniu::Auth.authorize_download_url(primitive_url)

      url = download_url
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      expect(response).to be_a(Net::HTTPSuccess)
      expect(response.body).to eq('Hello, OSS!')
    end
  end
end
