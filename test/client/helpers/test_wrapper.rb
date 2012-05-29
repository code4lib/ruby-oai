module Test::Unit
  class AutoRunner
    alias_method :real_run, :run
    
    def run
      ProviderServer.wrap { real_run }
    end

  end
  
end

unless $provider_server_already_started
  $provider_server_already_started = true
  ProviderServer.start(3333)
  sleep 2
end

