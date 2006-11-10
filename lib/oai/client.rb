# External dependencies
require 'uri'
require 'net/http'
require 'cgi'

if not defined?(OAI::Const::VERBS)
  # Shared stuff
  require 'oai/exception'
  require 'oai/constants'
  require 'oai/helpers'
  require 'oai/xpath'
  require 'oai/metadata_format'
  require 'oai/set'
end

# Localize requires so user can select a subset of functionality
require 'oai/client/response'
require 'oai/client/header'
require 'oai/client/record' 
require 'oai/client/identify'
require 'oai/client/get_record'
require 'oai/client/list_identifiers'
require 'oai/client/list_metadata_formats'
require 'oai/client/list_records'
require 'oai/client/list_sets'

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
    include Helpers

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
      return OAI::IdentifyResponse.new(do_request('Identify'))
    end

    # Equivalent to a ListMetadataFormats request. A ListMetadataFormatsResponse
    # object is returned to you. 
    
    def list_metadata_formats(opts={})
      return OAI::ListMetadataFormatsResponse.new(do_request('ListMetadataFormats', opts))
    end

    # Equivalent to a ListIdentifiers request. Pass in :from, :until arguments
    # as Date or DateTime objects as appropriate depending on the granularity 
    # supported by the server.
    
    def list_identifiers(opts={})
      return OAI::ListIdentifiersResponse.new(do_request('ListIdentifiers', opts)) 
    end

    # Equivalent to a GetRecord request. You must supply an identifier 
    # argument. You should get back a OAI::GetRecordResponse object
    # which you can extract a OAI::Record object from.
    
    def get_record(opts={})
      return OAI::GetRecordResponse.new(do_request('GetRecord', opts))
    end

    # Equivalent to the ListRecords request. A ListRecordsResponse
    # will be returned which you can use to iterate through records
    #
    #   for record in client.list_records
    #     puts record.metadata
    #   end
    
    def list_records(opts={})
      return OAI::ListRecordsResponse.new(do_request('ListRecords', opts))
    end

    # Equivalent to the ListSets request. A ListSetsResponse object
    # will be returned which you can use for iterating through the 
    # OAI::Set objects
    #
    #   for set in client.list_sets
    #     puts set
    #   end
    
    def list_sets(opts={})
      return OAI::ListSetsResponse.new(do_request('ListSets', opts))
    end

    private 

    def do_request(verb, opts = nil)
      # fire off the request and return appropriate DOM object
      uri = build_uri(verb, opts)
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
        puts e.message
        puts e.backtrace.join("\n")
        raise OAI::Exception, 'HTTP level error during OAI request: '+e, caller
      end
    end
    
    def build_uri(verb, opts)
      opts = validate_options(verb, opts)
      uri = @base.clone
      uri.query = "verb=" << verb
      opts.each_pair { |k,v| uri.query << '&' << externalize(k) << '=' << encode(v) }
      uri
    end
    
    def encode(value)
      return CGI.escape(value) unless value.respond_to?(:strftime)
      if value.respond_to?(:to_time) # Usually a DateTime or Time
        value.to_time.utc.xmlschema
      else # Assume something date like
        value.strftime('%Y-%m-%d')
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

    def debug(msg)
      $stderr.print("#{msg}\n") if @debug
    end
  end
end
