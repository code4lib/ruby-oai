require 'test_helper'

class HttpClientTest < Test::Unit::TestCase

  def test_pluggable_http_client
    oai_response = <<-eos
    <Identify>
      <repositoryName>Mock OAI Provider</repositoryName>
      <baseURL>http://nowhere.example.com</baseURL> 
    </Identify>
eos

    faraday_stub = Faraday.new do |builder|
      builder.adapter :test do |stub|
        stub.get('/oai?verb=Identify') { [200, {}, oai_response] }
      end
    end
    client = OAI::Client.new 'http://localhost:3333/oai', :http => faraday_stub
    response = client.identify

    assert_kind_of OAI::IdentifyResponse, response
    assert_equal 'Mock OAI Provider [http://nowhere.example.com]', response.to_s
    
  end
end

