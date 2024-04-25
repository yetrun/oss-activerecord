# oss-activerecord

一种用于将国内的云存储服务与 ActiveRecord 集成的解决方案。

## 写在最前

该 gem 主要包括两个部分：

1. 一个 OSS 服务的适配器，将不同的 OSS 服务抽象为统一的接口，方便在不同的 OSS 服务商之间切换。
2. 一个 OSS::Attachment 数据表，将 OSS 上传的对象纳入在一个表中管理，方便日后的迁移。

## 安装

在 Gemfile 中添加：

```ruby
gem 'oss-activerecord'
```

然后执行：

```bash
$ bundle
```

最后在 Ruby 项目中引入：

```ruby
require 'oss-activerecord'
```

## OSS Adapter

没有为 OSS Adapter 提供一个统一的类，而是提供不同的云厂商的适配器，你可以根据自己的需求选择合适的适配器。（这么做是因为 Ruby 语言不需要）

目前已支持的 OSS 服务商有：

- 阿里云 OSS：`OSS::Adapters::AliyunAdapter`
- 七牛云 OSS：`OSS::Adapters::QiniuAdapter`

### 创建 adapter

创建遵从相同的接口签名，以阿里云 OSS 为例：

```ruby
gem "aliyun-sdk"

require 'oss/adapters/aliyun_adapter'
adapter = OSS::Adapters::AliyunAdapter.new(
  access_key: 'your-access-key-id',
  secret_key: 'your-access-key-secret',
  endpoint: 'your-endpoint',
  bucket: 'your-bucket'
)
```

以七牛云 OSS 为例：

```ruby
gem "qiniu"

require 'oss/adapters/qiniu_adapter'
adapter = OSS::Adapters::QiniuAdapter.new(
  access_key: 'your-access-key',
  secret_key: 'your-secret-key',
  endpoint: 'your-endpoint',
  bucket: 'your-bucket'
)
```

### 上传文件

```ruby
adapter.upload('path/to/file', 'object-key')
```

### 返回签名 URL

```ruby
adapter.signed_url('object-key')
```

## `OSS::Attachment`

该模块主要是将所有与云存储对象相关的属性都关联一个表，方便统一管理和日后的迁移。同时，为了维护项目本身的兼容性，也为了适应更常见的需求，该模块将表关联的操作透明化。

### 准备工作

#### 创建表

在使用该模块之前，要求系统中已经存在一个 `oss_attachments` 表，类似的迁移脚本：

```ruby
create_table :oss_attachments do |t|
  t.string :object_key, comment: 'OSS 对象的 key'
  t.references :attachable, polymorphic: true, comment: '关联的对象'
  t.string :context, comment: '属性上下文'
end
```

#### 配置

```ruby
Attachment.endpoint = 'your-endpoint' # 解析 object_key 时需要
Attachment.use_signed_url = false # 是否返回签名 URL，默认为 false
Attachment.adapter = adapter # 如上构建的 OSS 适配器实例，解析签名 URL 时需要
```

### 关联模型

以 `User` 模型为例：

```ruby
class User < ActiveRecord::Base
  extend OSS::Attachment::Attachable
  
  has_one_attached :avatar, :avatar_url
end
```

该动作创建了一个 `avatar` 关联，同时创建了一个 `avatar_url` 的属性用于兼容性操作。

### 使用属性 URL

```ruby
user = User.new

# 保存 URL
user.avatar_url = 'object_key' # or full url、full url with signature
user.save! # 这一步才会写入数据库

# 读取 URL
user.avatar_url # get full url
```

### has_many_attached

除了 `has_one_attached` 之外，还支持 `has_many_attached`：

```ruby
class User < ActiveRecord::Base
  extend OSS::Attachment::Attachable
  
  has_many_attached :photos, :photo_urls
end
```

此时可以使用 `photo_urls` 进行操作。

```ruby
user = User.new

# 保存 URL
user.photo_urls = ['object_key1', 'object_key2'] # or full urls、full urls with signature
user.save! # 这一步才会写入数据库

# 读取 URL
user.photo_urls # get full urls
```

## 开发

```bash
git clone 本仓库

# 安装依赖项目
bundle

# 运行单元测试
bundle exec rspec

# 生成 gem
gem build oss-activerecord.gemspec

# 推送 gem
gem push oss-activerecord-x.x.x.gem
```

## 贡献

问题报告和 pull requests 在 GitHub 上：https://github.com/yetrun/oss-activerecord .
