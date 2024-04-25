# frozen_string_literal: true

RSpec.describe OSS::Attachment do
  # 准备 ActiveRecord 环境
  before(:context) do
    require 'active_record'

    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.define do
      create_table :oss_attachments, id: false do |t|
        t.string :object_key, null: false
        t.references :attachable, polymorphic: true
        t.string :context, null: false
      end

      create_table :users
    end
  end

  describe OSS::Attachment::Attachable do
    describe '.has_one_attached' do
      # 设置 endpoint
      before(:context) do
        OSS::Attachment.endpoint = 'http://example.com'
      end

      # 准备 Attachable 的类和父实例
      let(:user_class) do
        user_class = Class.new(ActiveRecord::Base)
        user_class.table_name = 'users'
        Object.const_set("X_#{SecureRandom.uuid.gsub('-', '_')}", user_class)
        user_class
      end
      let(:user) { user_class.new }

      # 调用 attached
      before(:example) do
        user_class.extend OSS::Attachment::Attachable
        user_class.has_one_attached :avatar, :avatar_url
      end

      it '初始的 avatar 为 nil' do
        expect(user.avatar).to be_nil
      end

      it '初始的 avatar_url 为 nil' do
        expect(user.avatar_url).to be_nil
      end

      it '重新设置 avatar 会自动复用之前的记录' do
        user.avatar_url = 'http://example.com/avatar.jpg'
        user.save!
        expect(OSS::Attachment.count).to eq(1), OSS::Attachment.all.inspect
        expect(OSS::Attachment.first.object_key).to eq('avatar.jpg')

        user.reload
        user.avatar_url = 'http://example2.com/avatar.jpg'
        user.save!
        expect(OSS::Attachment.count).to eq(1), OSS::Attachment.all.inspect
        expect(OSS::Attachment.first.object_key).to eq('http://example2.com/avatar.jpg')
      end

      describe '通过 url 属性设置和读取' do
        # 设置 URL，所有测试基于这个公共的回调
        before(:example) do
          user.avatar_url = url
          user.save!
          user.reload
        end

        shared_examples '设置的 URL 与 endpoint 不匹配' do
          context '设置的 URL 与 endpoint 不匹配' do
            let(:url) { 'http://example2.com/avatar.jpg' }

            it 'object_key 等于完整的 URL' do
              expect(user.avatar.object_key).to eq('http://example2.com/avatar.jpg')
            end

            it '读取的 URL 等于设置的 URL' do
              expect(user.avatar_url).to eq('http://example2.com/avatar.jpg')
            end
          end
        end

        context '普通的 URL' do
          let(:url) { 'http://example.com/avatar.jpg' }

          it 'object_key 等于去掉 endpoint 的结果' do
            expect(user.avatar.object_key).to eq('avatar.jpg')
          end

          it '读取的 URL 等于设置的 URL' do
            expect(user.avatar_url).to eq('http://example.com/avatar.jpg')
          end

          include_examples '设置的 URL 与 endpoint 不匹配'
        end

        context '签名 URL' do
          # 重新设置 endpoint
          before(:context) do
            @original_endpoint = OSS::Attachment.endpoint
            @original_url_signed = OSS::Attachment.use_signed_url

            OSS::Attachment.endpoint = 'http://mkj-private.oss-cn-shanghai.aliyuncs.com'
            OSS::Attachment.use_signed_url = true
            require 'oss/adapters/aliyun_adapter'
            OSS::Attachment.oss_adapter = OSS::Adapters::AliyunAdapter.new(
              endpoint: 'https://oss-cn-shanghai.aliyuncs.com',
              access_key: 'XXX',
              secret_key: 'XXX',
              bucket: 'mkj-private'
            )
          end

          # 恢复原本的 endpoint
          after(:context) do
            OSS::Attachment.endpoint = @original_endpoint
            OSS::Attachment.use_signed_url = @original_url_signed
          end

          let(:url) { 'http://mkj-private.oss-cn-shanghai.aliyuncs.com/hello.txt?Expires=1600000000&OSSAccessKeyId=LTAI4&Signature=iBNb' }

          it 'endpoint 应该已重新设置' do
            expect(OSS::Attachment.endpoint).to eq('http://mkj-private.oss-cn-shanghai.aliyuncs.com')
          end

          it 'object_key 等于去掉 endpoint 和 query 参数的结果' do
            expect(user.avatar.object_key).to eq('hello.txt')
          end

          it '读取的 URL 包括 完整的 endpoint和 query 部分' do
            avatar_url = user.avatar_url
            expect(avatar_url).to start_with('https://mkj-private.oss-cn-shanghai.aliyuncs.com/hello.txt')
            expect(avatar_url).to include('?')
          end

          include_examples '设置的 URL 与 endpoint 不匹配'
        end
      end
    end

    # 迅速地从 describe '.has_one_attached' 导出一份测试
    describe '.has_many_attached' do
      # 设置 endpoint
      before(:context) do
        OSS::Attachment.endpoint = 'http://example.com'
      end

      # 准备 Attachable 的类和父实例
      let(:user_class) do
        user_class = Class.new(ActiveRecord::Base)
        user_class.table_name = 'users'
        Object.const_set("X_#{SecureRandom.uuid.gsub('-', '_')}", user_class)
        user_class
      end
      let(:user) { user_class.new }

      # 调用 attached
      before(:example) do
        user_class.extend OSS::Attachment::Attachable
        user_class.has_many_attached :avatars, :avatar_urls
        user_class.define_method(:avatar) do
          avatars.first
        end
        user_class.define_method(:avatar_url) do
          avatar_urls.first
        end
      end

      it '初始的 avatar 为 nil' do
        expect(user.avatars).to be_empty
      end

      it '初始的 avatar_url 为 nil' do
        expect(user.avatar_urls).to be_empty
      end

      it '设置 records' do
        user.avatars = [OSS::Attachment.new(object_key: 'avatar1.jpg', context: 'avatars'), OSS::Attachment.new(object_key: 'avatar2.jpg', context: 'avatars')]
        user.save!
      end

      it '重新设置 avatar 会自动删除之前的记录' do
        user.avatar_urls = ['http://example.com/avatar1.jpg', 'http://example.com/avatar2.jpg']
        user.save!
        avatars = OSS::Attachment.where(attachable: user)
        expect(avatars.count).to eq(2), OSS::Attachment.all.inspect
        expect(avatars.map(&:object_key)).to eq(['avatar1.jpg', 'avatar2.jpg'])

        user.reload
        user.avatar_urls = ['http://example2.com/avatar1.jpg', 'http://example2.com/avatar2.jpg']
        user.save!
        avatars = OSS::Attachment.where(attachable: user)
        expect(avatars.count).to eq(2), OSS::Attachment.all.inspect
        expect(avatars.map(&:object_key)).to eq(['http://example2.com/avatar1.jpg', 'http://example2.com/avatar2.jpg'])
      end

      describe '通过 url 属性设置和读取' do
        # 设置 URL，所有测试基于这个公共的回调
        before(:example) do
          user.avatar_urls = [url]
          user.save!
          user.reload
        end

        shared_examples '设置的 URL 与 endpoint 不匹配' do
          context '设置的 URL 与 endpoint 不匹配' do
            let(:url) { 'http://example2.com/avatar.jpg' }

            it 'object_key 等于完整的 URL' do
              expect(user.avatar.object_key).to eq('http://example2.com/avatar.jpg')
            end

            it '读取的 URL 等于设置的 URL' do
              expect(user.avatar_url).to eq('http://example2.com/avatar.jpg')
            end
          end
        end

        context '普通的 URL' do
          let(:url) { 'http://example.com/avatar.jpg' }

          it 'object_key 等于去掉 endpoint 的结果' do
            expect(user.avatar.object_key).to eq('avatar.jpg')
          end

          it '读取的 URL 等于设置的 URL' do
            expect(user.avatar_url).to eq('http://example.com/avatar.jpg')
          end

          include_examples '设置的 URL 与 endpoint 不匹配'
        end

        context '签名 URL' do
          # 重新设置 endpoint
          before(:context) do
            @original_endpoint = OSS::Attachment.endpoint
            @original_url_signed = OSS::Attachment.use_signed_url

            OSS::Attachment.endpoint = 'http://mkj-private.oss-cn-shanghai.aliyuncs.com'
            OSS::Attachment.use_signed_url = true
            require 'oss/adapters/aliyun_adapter'
            OSS::Attachment.oss_adapter = OSS::Adapters::AliyunAdapter.new(
              endpoint: 'https://oss-cn-shanghai.aliyuncs.com',
              access_key: 'XXX',
              secret_key: 'XXX',
              bucket: 'mkj-private'
            )
          end

          # 恢复原本的 endpoint
          after(:context) do
            OSS::Attachment.endpoint = @original_endpoint
            OSS::Attachment.use_signed_url = @original_url_signed
          end

          let(:url) { 'http://mkj-private.oss-cn-shanghai.aliyuncs.com/hello.txt?Expires=1600000000&OSSAccessKeyId=LTAI4&Signature=iBNb' }

          it 'endpoint 应该已重新设置' do
            expect(OSS::Attachment.endpoint).to eq('http://mkj-private.oss-cn-shanghai.aliyuncs.com')
          end

          it 'object_key 等于去掉 endpoint 和 query 参数的结果' do
            expect(user.avatar.object_key).to eq('hello.txt')
          end

          it '读取的 URL 包括 完整的 endpoint和 query 部分' do
            avatar_url = user.avatar_url
            expect(avatar_url).to start_with('https://mkj-private.oss-cn-shanghai.aliyuncs.com/hello.txt')
            expect(avatar_url).to include('?')
          end

          include_examples '设置的 URL 与 endpoint 不匹配'
        end
      end
    end
  end
end
