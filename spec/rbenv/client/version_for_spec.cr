require "../../spec_helper"
require "rbenv/client"

class Rbenv::Client
  def initialize( @versions )
  end
end

describe Rbenv::Client do
  describe "#version_for" do
    client = Rbenv::Client.new [
      "2.3.4",
      "2.3.6",
      "2.3.7",
      "2.4.3",
      "2.4.4",
      "2.5.0",
      "2.5.1"
    ]
    
    it "should handle exact versions" do
      client.version_for( "2.3.6" ).should eq "2.3.6"
      client.version_for( "2.5.1" ).should eq "2.5.1"
    end
    
    it "should handle ~> requirements" do
      client.version_for( "~> 2.3.0" ).should eq "2.3.7"
      client.version_for( "~> 2.3.4" ).should eq "2.3.7"
      client.version_for( "~> 2.4.0" ).should eq "2.4.4"
      client.version_for( "~> 2.4.4" ).should eq "2.4.4"
      client.version_for( "~> 2.5.0" ).should eq "2.5.1"
      client.version_for( "~> 2.3" ).should eq "2.5.1"
    end
    
    it "should handle >= requirements" do
      client.version_for( ">= 2.3.0" ).should eq "2.5.1"
      client.version_for( ">= 2.4.4" ).should eq "2.5.1"
    end
    
  end
end
