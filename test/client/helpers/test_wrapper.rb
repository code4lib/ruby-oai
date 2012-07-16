unless $provider_server
  $provider_server = ProviderServer.new(3333, '/oai')
  $provider_server.start
  sleep 0.2
end

