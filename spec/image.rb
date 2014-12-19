require 'spec_helper'

describe "image" do
  it "should expose the mysql tcp port" do
    expect(IMAGE.json["Config"]["ExposedPorts"]).to include("3306/tcp")
  end
end