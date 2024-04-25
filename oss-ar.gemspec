# frozen_string_literal: true

require_relative "lib/oss-activerecord/version"

Gem::Specification.new do |spec|
  spec.name = "oss-ar"
  spec.version = OSS::VERSION
  spec.authors = ["yetrun"]
  spec.email = ["yetrun@foxmail.com"]
  spec.license = "LGPL-2.0"

  spec.summary = "将国内的云存储服务与 ActiveRecord 集成的解决方案"
  # spec.description = "description"
  spec.homepage = "https://github.com/yetrun/oss-activerecord"
  spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "allowed_push_host"

  spec.metadata["homepage_uri"] = spec.homepage if spec.homepage
  # spec.metadata["source_code_uri"] = "github"
  # spec.metadata["changelog_uri"] = "change_log"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files = Dir.chdir(__dir__) do
  #   `git ls-files -z`.split("\x0").reject do |f|
  #     (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
  #   end
  # end

  spec.files = [
    "lib/oss-activerecord.rb",
    "lib/oss-activerecord/attachment.rb",
    "lib/oss-activerecord/version.rb",
    "lib/oss/adapters/aliyun_adapter.rb",
    "lib/oss/adapters/qiniu_adapter.rb"
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "sorbet-runtime", "~> 0.5"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
