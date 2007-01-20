require 'time'
require 'enumerator'
require File.dirname(__FILE__) + "/partial_result"

module OAI
  
  class ResumptionToken
    
    def initialize(token, expiration = nil, total = nil)
      @attrs = {:token => token}
      @attrs[:completeListSize] = total if total
      @attrs[:expirationDate] = expiration.utc.xmlschema if expiration
    end
    
    def to_xml(xml)
      xml.resumptionToken(@attrs.delete(:token), @attrs)
    end
  end
  
  module ResumptionHelpers
    
    def token(opts)
      return opts[:resumption_token]
    end
    
    def generate_token(opts)
      constrain_from_until(opts)
      key = opts[:metadata_prefix].dup
      key << ".s(#{opts[:set]})" if opts[:set]
      key << %{.f(#{opts[:from].utc.xmlschema})} if opts[:from]
      key << %{.u(#{opts[:until].utc.xmlschema})} if opts[:until]
      key
    end
    
    # set from to earliest timestamp and until to latest timestamp,
    # unless values are provided.
    def constrain_from_until(opts)
      opts[:from] = earliest unless opts[:from]
      opts[:until] = latest unless opts[:until]
    end

    def extract_token_and_offset(token)
      begin
        matches = /(.+):(\d+)$/.match(token)
        return matches.captures[0], matches.captures[1].to_i
      rescue
        raise ResumptionTokenException.new
      end
    end
    
    def extract_conditions_from_token(token)
      bits = token.split('.')
      conditions = {:metadata_prefix => bits.shift}
      bits.each do |bit|
        case bit
        when /^s/
          conditions[:set] = bit.sub(/^s\(/, '').sub(/\)$/, '')
        when /^f/
          conditions[:from] = Time.parse(bit.sub(/^f\(/, '').sub(/\)$/, '')).localtime
        when /^u/
          conditions[:until] = Time.parse(bit.sub(/^f\(/, '').sub(/\)$/, '')).localtime
        end
      end
      return conditions
    end
    
    def generate_chunks(records, limit)
      groups = []
      records.each_slice(limit) do |group|
        groups << group
      end
      groups
    end
    
    # We can extract the metadata format from any resumption token by 
    # splitng on '.', taking the first result and removing a trailing ':'
    def metadata_format(token)
      token.split('.')[0].gsub(/:.*$/, '')
    end
    
  end
          
end
