# frozen_string_literal: true

require 'active_record'

module OSS
  class Attachment < ActiveRecord::Base
    extend T::Sig

    self.primary_key = :object_key
    self.table_name = 'oss_attachments'

    validates :object_key, presence: true, uniqueness: { scope: %i[attachable_id attachable_type context] }

    belongs_to :attachable, polymorphic: true, optional: false, autosave: true

    sig {returns(T.nilable(String))}
    def url
      return object_key if object_key.nil? || full_url?(object_key)

      if self.class.use_signed_url
        self.class.oss_adapter.signed_url(object_key)
      else
        File.join(self.class.endpoint, object_key)
      end
    end

    sig {params(url: T.nilable(String)).void}
    def url=(url)
      if url.nil?
        self.object_key = nil
      else
        self.object_key = self.class.resolve_object_key(url)
      end
    end

    private

    def full_url?(url)
      url.start_with?(%r{https?://})
    end

    class << self
      extend T::Sig

      attr_accessor :endpoint, :use_signed_url, :oss_adapter

      sig {params(object_key: String).returns(String)}
      def signed_url(object_key)
        oss_adapter.signed_url(object_key)
      end

      sig {params(url: String).returns(String)}
      def resolve_object_key(url)
        return url unless descendant_of_endpoint?(url)

        # 首先去掉 url 的 query 部分
        url = url.split('?').first
        # 然后获取相对路径
        p = Pathname.new(url).relative_path_from(Pathname.new(endpoint))

        p.to_s
      end

      sig {params(object_key: String).returns(String)}
      def resolve_full_url(object_key)
        return object_key if object_key.nil? || full_url?(object_key)

        if use_signed_url
          oss_adapter.signed_url(object_key)
        else
          File.join(endpoint, object_key)
        end
      end

      private

      def full_url?(url)
        url.start_with?(%r{https?://})
      end

      def descendant_of_endpoint?(url)
        endpoint = self.endpoint

        # 确保尾部有斜杠
        endpoint = "#{endpoint}/" unless endpoint.end_with?('/')
        url = "#{url}/" unless url.end_with?('/')

        # 检查 url 是否是 endpoint 的子路径
        url.start_with?(endpoint)
      end
    end

    module Attachable
      extend T::Sig

      sig {params(association_name: Symbol, attribute_name: Symbol).void}
      def has_one_attached(association_name, attribute_name)
        has_one association_name, ->{ where(context: association_name) }, class_name: 'OSS::Attachment', as: :attachable

        define_method("#{attribute_name}=") do |url|
          attachment = send(association_name) || Attachment.new(context: association_name)
          object_key = Attachment.resolve_object_key(url)
          attachment.object_key = object_key
          send("#{association_name}=", attachment)
        end

        define_method(attribute_name) do
          record = send(association_name)
          record&.url
        end
      end

      sig {params(association_name: Symbol, attribute_name: Symbol).void}
      def has_many_attached(association_name, attribute_name)
        has_many association_name, ->{ where context: association_name }, class_name: 'OSS::Attachment', as: :attachable, dependent: :delete_all, validate: false

        define_method("#{attribute_name}=") do |urls|
          object_keys = urls.map { |url| Attachment.resolve_object_key(url) }

          attachments = object_keys.map do |object_key|
            Attachment.new(context: association_name, object_key: object_key)
          end
          send("#{association_name}=", attachments)
        end

        define_method(attribute_name) do
          record = send(association_name)
          record.map(&:url)
        end
      end
    end
  end
end
