module OAI

  # An OAI::Response contains entries and a resumption token. If a resumption token is present,
  # then you must use it to fetch the rest of the entries for your query. For example:
  #
  # ```ruby
  #  # List all records in a given set
  #  client = OAI::Client.new 'http://my-oai-provider.example.com/oai'
  #  response = client.list_records :set => 'my_set_name'
  #  while response.entries.count > 0
  #    response.entries.each { |entry|
  #      puts entry.header.identifier
  #    }
  #    token = response.resumption_token
  #    # Note: You do not need to pass the options hash again, just the verb and the resumption token
  #    response = client.list_records :resumption_token => token if token
  #  end
  # ```
  class Response
    include OAI::XPath
    attr_reader :doc, :resumption_token, :resumption_block, :complete_list_size

    def initialize(doc, &resumption_block)
      @doc = doc
      rt_node = xpath_first(doc, './/resumptionToken')
      @resumption_token = get_text(rt_node)
      @complete_list_size = get_attribute(rt_node, 'completeListSize')
      @resumption_block = resumption_block

      # throw an exception if there was an error
      error = xpath_first(doc, './/error')
      return unless error

      case error.class.to_s
        when 'REXML::Element'
          message = error.text
          code = error.attributes['code']
        when 'LibXML::XML::Node'
          message = error.content
          code = ""
          if defined?(error.property) == nil
            code = error.attributes['code']
         else
           begin
             code = error["code"]
           rescue
             code = error.property('code')
           end
         end
      end
      raise OAI::Exception.new(message, code)
    end

  end
end
