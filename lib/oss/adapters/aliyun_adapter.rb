# frozen_string_literal: true

require 'aliyun/oss'

module OSS
  module Adapters
    class AliyunAdapter
      extend T::Sig

      sig {params(endpoint: String, access_key: String, secret_key: String, bucket: String).void}
      def initialize(endpoint:, access_key:, secret_key:, bucket:)
        @client = Aliyun::OSS::Client.new(
          endpoint: endpoint,
          access_key_id: access_key,
          access_key_secret: secret_key
        )
        @bucket = @client.get_bucket(bucket)
      end

      sig {params(filepath: String, object_key: String).void}
      def upload(filepath, object_key)
        @bucket.put_object(object_key, file: filepath)
      end

      sig {params(object_key: String).returns(String)}
      def signed_url(object_key)
        @bucket.object_url(object_key, true, 60)
      end
    end
  end
end
