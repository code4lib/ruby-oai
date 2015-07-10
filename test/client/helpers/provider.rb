require 'webrick'
require File.dirname(__FILE__) + '/../../provider/models'

class ComplexProvider < OAI::Provider::Base
  repository_name 'Complex Provider'
  repository_url 'http://localhost'
  record_prefix 'oai:test'
  source_model ComplexModel.new(100)
end

class ProviderServer

  attr_reader :consumed, :server

  def initialize(port, mount_point)
    @consumed = []
    @provider = ComplexProvider.new
    @server = WEBrick::HTTPServer.new(
      :BindAddress => '127.0.0.1',
      :Logger => WEBrick::Log.new('/dev/null'),
      :AccessLog => [],
      :Port => port)
    @server.mount_proc(mount_point, server_proc)
  end

  def port
    @server.config[:Port]
  end

  def start
    @thread = Thread.new { @server.start }
  end

  def stop
    @thread.exit if @thread
  end

  def self.wrap(port = 3333, mount_point='/oai')
    server = self.new(port, mount_point)
    begin
      server.start
      yield(server)
    ensure
      server.stop
    end
  end

  protected

  def server_proc
    Proc.new do |req, res|
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
    end
  end

end