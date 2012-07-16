require 'test_helper'
require 'webrick'

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

  def test_http_client_handles_trailing_slash_redirects
    # First, test that this works when mocking out Faraday client
    oai_response = <<-eos
      <Identify>
        <repositoryName>Mock OAI Provider</repositoryName>
        <baseURL>http://nowhere.example.com</baseURL>
      </Identify>
    eos

    stubs = TrailingSlashAwareStubs.new do |stub|
      stub.get('/oai/?verb=Identify') { [200, {}, oai_response] }
      stub.get('/oai?verb=Identify') {
        [301, {
          'Location' => 'http://localhost:3334/oai/?verb=Identify'
        }, '']
      }
    end

    faraday_stub = Faraday.new do |builder|
      require 'faraday_middleware'
      builder.use FaradayMiddleware::FollowRedirects
      builder.adapter :test, stubs
    end

    client = OAI::Client.new 'http://localhost:3334/oai', :http => faraday_stub
    response = client.identify

    assert_kind_of OAI::IdentifyResponse, response
    assert_equal 'Mock OAI Provider [http://nowhere.example.com]', response.to_s
    assert_equal 2, stubs.consumed[:get].length
    assert_equal stubs.consumed[:get].first.path, '/oai'
    assert_equal stubs.consumed[:get].last.path, '/oai/'

    # Now try it with a real server and default Faraday client
    TrailingSlashProviderServer.wrap(3334) do |server|
      client = OAI::Client.new "http://localhost:#{server.port}/oai"
      response = client.identify

      assert_kind_of OAI::IdentifyResponse, response
      assert_equal 'Complex Provider [http://localhost]', response.to_s
      assert_equal 2, server.consumed.length
      assert_equal server.consumed.first.path, '/oai'
      assert_equal server.consumed.last.path, '/oai/'
    end
  end

  private

  class TrailingSlashProviderServer < ProviderServer
    def server_proc
      Proc.new do |req, res|
        @consumed << req
        case req.path
        when "/oai/"
          begin
            res.body = @provider.process_request(req.query)
            res.status = 200
            res['Content-Type'] = 'text/xml'
          rescue => err
            puts err
            puts err.backtrace.join("\n")
            res.body = err.backtrace.join("\n")
            res.status = 500
          end
        else
          res.body = ''
          res.status = 301
          res['Location'] = "http://localhost:#{port}/oai/?#{req.query_string}"
        end
        res
      end
    end
  end

  class TrailingSlashAwareStubs < Faraday::Adapter::Test::Stubs
    attr_reader :consumed

    # ensure leading, but not trailing slash
    def normalize_path(path)
      path = '/' + path if path.index('/') != 0
      #path = path.sub('?', '/?')
      #path = path + '/' unless $&
      path.gsub('//', '/')
    end

  end
end

