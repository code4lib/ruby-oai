require 'uri'
require 'net/http'
require 'rexml/document'
require 'cgi'

module OAI

  # A OAI::Client provides a client api for issuing OAI-PMH verbs against
  # a OAI-PMH server. The 6 OAI-PMH verbs translate directly to methods you 
  # can call on a OAI::Client object. Verb arguments are passed as a hash:
  #
  #   client = OAI::Client.new ''http://www.pubmedcentral.gov/oai/oai.cgi'
  #   client.list_identifiers :metadata_prefix => 'oai_dc'
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
    
    def initialize(base_url)
      @base = URI.parse base_url
    end

    # Equivalent to a Identify request. You'll get back a OAI::IdentifyResponse
    # object which is essentially just a wrapper around a REXML::Document 
    # for the response.
    
    def identify
      return IdentifyResponse.new(do_request(:verb => 'Identify'))
    end

    # Equivalent to a ListMetadataFormats request. A ListMetadataFormatsResponse
    # object is returned to you. 
    
    def list_metadata_formats(opts={})
      opts[:verb] = 'ListMetadataFormats'
      verify_verb_arguments opts, [:verb, :identifier]
      return ListMetadataFormatsResponse.new(do_request(opts))
    end

    # Equivalent to a ListIdentifiers request. Pass in :from, :until arguments
    # as Date or DateTime objects as appropriate depending on the granularity 
    # supported by the server.
    
    def list_identifiers(opts={})
      opts[:verb] = 'ListIdentifiers'
      add_default_metadata_prefix opts
      verify_verb_arguments opts, [:verb, :from, :until, :metadata_prefix, :set,         :resumption_token]
      return ListIdentifiersResponse.new(do_request(opts)) 
    end

    # Equivalent to a GetRecord request. You must supply an identifier 
    # argument. You should get back a OAI::GetRecordResponse object
    # which you can extract a OAI::Record object from.
    
    def get_record(opts={})
      opts[:verb] = 'GetRecord'
      add_default_metadata_prefix opts
      verify_verb_arguments opts, [:verb, :identifier, :metadata_prefix]
      return GetRecordResponse.new(do_request(opts))
    end

    # Equivalent to the ListRecords request. A ListRecordsResponse
    # will be returned which you can use to iterate through records
    #
    #   for record in client.list_records
    #     puts record.metadata
    #   end
    
    def list_records(opts={})
      opts[:verb] = 'ListRecords'
      add_default_metadata_prefix opts
      verify_verb_arguments opts, [:verb, :from, :until, :set, 
        :resumption_token, :metadata_prefix]
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
      opts[:verb] = 'ListSets'
      verify_verb_arguments opts, [:verb, :resumptionToken]
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

      # fire off the request and return an REXML::Document object
      begin
        xml = Net::HTTP.get(uri)
        return REXML::Document.new(xml)
      rescue
        raise OAI::Exception, 'error during oai operation', caller
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

    def verify_verb_arguments(opts, valid_opts)
      opts.keys.each do |opt|
        if opt =~ /[A-Z]/
          raise OAI::Exception.new("#{opt} should use underscores")
        elsif not valid_opts.include? opt 
          raise OAI::Exception.new("invalid option #{opt} in #{opts['verb']}")
        end
      end
    end
  end
end
