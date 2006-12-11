#$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
#require File.dirname(__FILE__) + '/../lib/oai'
#require 'test_models'

require 'webrick'

class ProviderServer < WEBrick::HTTPServlet::AbstractServlet
  @@server = nil
  
  def initialize(server)
    super(server)
    @provider = ComplexProvider.new
  end
  
  def do_GET(req, res)
    begin
      res.body = @provider.process_verb(req.query.delete("verb"), req.query)
      res.status = 200
      res['Content-Type'] = 'text/xml'
    rescue 
      puts $!
      puts $!.backtrace.join("\n")
      res.body = nil
      res.status = 500
    end
  end
  
  def self.start
    unless @@server
      logger = WEBrick::Log.new("/dev/null")
      @@server = WEBrick::HTTPServer.new(
        :BindAddress => '127.0.0.1', 
        :AccessLog => logger,
        :Logger => logger, 
        :Port => 3333)
      @@server.mount("/oai", ProviderServer)

      trap("INT") { @@server.shutdown }
      @@thread = Thread.new { @@server.start }
      sleep 2
    end
  end
    
end
