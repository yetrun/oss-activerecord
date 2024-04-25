# frozen_string_literal: true

RSpec.describe OSS do
  it "has a version number" do
    expect(OSS::VERSION).not_to be nil
  end
end
