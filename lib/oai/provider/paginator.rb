# = paginator.rb
#
# Large response sets can be broken down into smaller sub documents thru the use
# of resumption tokens.
#
# Will Groppe mailto: wfg@artstor.org
#
require 'enumerator'

module OAI
  
  class Paginator
    attr_reader :chunk_size, :last_requested
    
    def initialize(chunk_size = 25)
      @chunk_size = chunk_size
    end
    
    def paginate(query, records)
      requested
      paginate_response(query, records)
    end
    
    def get_chunk(token)
      raise NotImplementedError.new
    end
    
    def query_cached?(query)
      raise NotImplementedError.new
    end

    protected 
    
    def paginate_response(records = [])
      raise NotImplementedError.new
    end
    
    def generate_chunks(records)
      groups = []
      records.each_slice(chunk_size) do |group|
        groups << group
      end
      groups
    end
    
    def requested
      @last_requested = Time.now
    end

  end

end

require 'oai/provider/paginator/simple_paginator'
