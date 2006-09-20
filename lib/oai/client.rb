require 'uri'
require 'net/http'
require 'cgi'
require 'date'

module OAI

  # A OAI::Client provides a client api for issuing OAI-PMH verbs against
  # a OAI-PMH server. The 6 OAI-PMH verbs translate directly to methods you 
  # can call on a OAI::Client object. Verb arguments are passed as a hash:
  #
  #   client = OAI::Client.new 'http://www.pubmedcentral.gov/oai/oai.cgi'
  #   record = client.get_record :identifier => 'oai:pubmedcentral.gov:13901'
  #   for identifier in client.list_identifiers :metadata_prefix => 'oai_dc'
  #     puts identifier.
  #
  # It is worth noting that the api uses methods and parameter names with 
  # underscores in them rather than studly caps. So above list_identifiers 
  # and metadata_prefix are used instead of the listIdentifiers and 
  # metadataPrefix used in the OAI-PMH specification.
  #
  # Also, the from and until arguments which specify dates should be passed
  # in as Date or DateTime objects depending on the granularity supported
  # by the server.
  #
  # For detailed information on the arguments that can be used please consult
  # the OAI-PMH docs at:
  #
  #     http://www.openarchives.org/OAI/openarchivesprotocol.html
  
  class Client

    # The constructor which must be passed a valid base url for an oai 
    # service:
    #
    #   client = OAI::Harvseter.new 'http://www.pubmedcentral.gov/oai/oai.cgi'
    #
    # If you want to see debugging messages on STDERR use:
    #
    #   client = OAI::Harvester.new 'http://example.com', :debug => true
    #
    # By default OAI verbs called on the client will return REXML::Element
    # objects for metadata records, however if you wish you can use the
    # :parser option to indicate you want to use 'libxml' instead, and get
    # back XML::Node objects
    #
    #   client = OAI::Harvester.new 'http://example.com', :parser => 'libxml'
    
    def initialize(base_url, options={})
      @base = URI.parse base_url
      @debug = options.fetch(:debug, false)
      @parser = options.fetch(:parser, 'rexml')
      
      # load appropriate parser
      case @parser
      when 'libxml'
        begin
	  require 'rubygems'
          require 'xml/libxml'
        rescue
          raise OAI::Exception.new("xml/libxml not available")
        end
      when 'rexml'
        require 'rexml/document'
        require 'rexml/xpath'
      else
        raise OAI::Exception.new("unknown parser: #{@parser}")
      end
    end

    # Equivalent to a Identify request. You'll get back a OAI::IdentifyResponse
    # object which is essentially just a wrapper around a REXML::Document 
    # for the response. If you are created your client using the libxml 
    # parser then you will get an XML::Node object instead.
    
    def identify
      return IdentifyResponse.new(do_request(:verb => 'Identify'))
    end

    # Equivalent to a ListMetadataFormats request. A ListMetadataFormatsResponse
    # object is returned to you. 
    
    def list_metadata_formats(opts={})
      sanitize_verb_arguments 'ListMetadataFormats', opts, [:verb, :identifier]
      return ListMetadataFormatsResponse.new(do_request(opts))
    end

    # Equivalent to a ListIdentifiers request. Pass in :from, :until arguments
    # as Date or DateTime objects as appropriate depending on the granularity 
    # supported by the server.
    
    def list_identifiers(opts={})
      sanitize_verb_arguments 'ListIdentifiers', opts, 
        [:verb, :from, :until, :metadata_prefix, :set, :resumption_token]
      add_default_metadata_prefix opts
      return ListIdentifiersResponse.new(do_request(opts)) 
    end

    # Equivalent to a GetRecord request. You must supply an identifier 
    # argument. You should get back a OAI::GetRecordResponse object
    # which you can extract a OAI::Record object from.
    
    def get_record(opts={})
      sanitize_verb_arguments 'GetRecord', opts, 
        [:verb, :identifier, :metadata_prefix]
      add_default_metadata_prefix opts
      return GetRecordResponse.new(do_request(opts))
    end

    # Equivalent to the ListRecords request. A ListRecordsResponse
    # will be returned which you can use to iterate through records
    #
    #   for record in client.list_records
    #     puts record.metadata
    #   end
    
    def list_records(opts={})
      sanitize_verb_arguments 'ListRecords', opts, [:verb, :from, :until, :set, 
        :resumption_token, :metadata_prefix]
      add_default_metadata_prefix opts
      return ListRecordsResponse.new(do_request(opts))
    end

    # Equivalent to the ListSets request. A ListSetsResponse object
    # will be returned which you can use for iterating through the 
    # OAI::Set objects
    #
    #   for set in client.list_sets
    #     puts set
    #   end
    
    def list_sets(opts={})
      sanitize_verb_arguments 'ListSets', opts, [:verb, :resumptionToken]
      return ListSetsResponse.new(do_request(opts))
    end

    private 

    def do_request(hash)
      uri = @base.clone

      # build up the query string
      parts = hash.entries.map do |entry|
        key = studly(entry[0].to_s)
        value = entry[1]
        # dates get stringified using ISO8601, strings are url encoded
        value = case value
          when DateTime then value.strftime('%Y-%m-%dT%H:%M:%SZ'); 
          when Date then value.strftime('%Y-%m-%d')
          else CGI.escape(entry[1].to_s)
        end
        "#{key}=#{value}"
      end
      uri.query = parts.join('&')
      debug("doing request: #{uri.to_s}")

      # fire off the request and return appropriate DOM object
      begin
        xml = Net::HTTP.get(uri)
	if @parser == 'libxml' 
          # remove default namespace for oai-pmh since libxml
          # isn't able to use our xpaths to get at them 
          # if you know a way around thins please let me know
          xml = xml.gsub(
            /xmlns=\"http:\/\/www.openarchives.org\/OAI\/.\..\/\"/, '') 
        end
        return load_document(xml)
      rescue StandardError => e
        raise OAI::Exception, 'HTTP level error during OAI request: '+e, caller
      end
    end

    def load_document(xml)
      case @parser
      when 'libxml'
        begin
          parser = XML::Parser.new()
          parser.string = xml
          return parser.parse
        rescue XML::Parser::ParseError => e
          raise OAI::Exception, 'response not well formed XML: '+e, caller
        end
      when 'rexml'
        begin
          return REXML::Document.new(xml)
        rescue REXML::ParseException => e
          raise OAI::Exception, 'response not well formed XML: '+e, caller
        end
      end
    end

    # convert foo_bar to fooBar thus allowing our ruby code to use
    # the typical underscore idiom
    def studly(s)
      s.gsub(/_(\w)/) do |match|
        match.sub! '_', ''
        match.upcase
      end
    end

    # add a metadata prefix unless it's there or we are working with 
    # a resumption token, and having one added could cause problems
    def add_default_metadata_prefix(opts)
      unless opts.has_key? :metadata_prefix or opts.has_key? :resumption_token
        opts[:metadata_prefix] = 'oai_dc'
      end
    end

    def sanitize_verb_arguments(verb, opts, valid_opts)
      # opts could mistakenly not be a hash if the method was called wrong
      # client.get_record(12) instead of client.get_record(:identifier => 12)
      unless opts.kind_of?(Hash)
        raise OAI::Exception.new("method options must be passed as a hash") 
      end

      # add the verb
      opts[:verb] = verb

      # make sure options aren't using studly caps, and that they're legit
      opts.keys.each do |opt|
        if opt =~ /[A-Z]/
          raise OAI::Exception.new("#{opt} should use underscores")
        elsif not valid_opts.include? opt 
          raise OAI::Exception.new("invalid option #{opt} in #{opts['verb']}")
        end
      end
    end

    def debug(msg)
      $stderr.print("#{msg}\n") if @debug
    end
  end
end
