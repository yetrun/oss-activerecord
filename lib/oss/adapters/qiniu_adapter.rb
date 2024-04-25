# frozen_string_literal: true

require 'qiniu'

module OSS
  module Adapters
    class QiniuAdapter
      extend T::Sig

      sig {params(endpoint: String, access_key: String, secret_key: String, bucket: String).void}
      def initialize(endpoint: ,access_key:, secret_key:, bucket:)
        Qiniu.establish_connection! access_key: access_key, secret_key: secret_key
        @endpoint = endpoint
        @bucket = bucket
      end

      sig {params(filepath: String, object_key: String).void}
      def upload(filepath, object_key)
        # 构建上传策略，上传策略的更多参数请参照 http://developer.qiniu.com/article/developer/security/put-policy.html
        put_policy = Qiniu::Auth::PutPolicy.new(
          @bucket, # 存储空间
          object_key,    # 指定上传的资源名，如果传入 nil，就表示不指定资源名，将使用默认的资源名
          3600    # token 过期时间，默认为 3600 秒，即 1 小时
        )
        # 生成上传 Token
        uptoken = Qiniu::Auth.generate_uptoken(put_policy)
        # 调用 upload_with_token_2 方法上传
        Qiniu::Storage.upload_with_token_2(
          uptoken,
          filepath,
          object_key,
          nil, # 可以接受一个 Hash 作为自定义变量，请参照 http://developer.qiniu.com/article/kodo/kodo-developer/up/vars.html#xvar
          bucket: @bucket
        )
      end

      sig {params(object_key: String).returns(String)}
      def signed_url(object_key)
        primitive_url = File.join(@endpoint, object_key)
        Qiniu::Auth.authorize_download_url(primitive_url)
      end
    end
  end
end
