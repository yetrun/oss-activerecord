RSpec.describe 'extend 的签名' do
  require 'sorbet-runtime'

  module FinderMethods
    extend T::Sig
    # extend T::Generic
    # abstract!

    # has_attached_class!

    # sig {abstract.returns(T.attached_class)}
    # def new; end

    sig {params(id: String).returns(T.attached_class)}
    def find(id)
      self.new
    end
  end

  class Model
    extend T::Sig
    extend FinderMethods
  end

  Model.find(1)
end
