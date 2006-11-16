# = response_set.rb
#
# Will Groppe mailto: wfg@artstor.org
#

module OAI
  
  class ResponseSet
    attr :model, :chunk_size, :query
    
    def initialize(model, query, chunk_size = nil)
      @model = model
      @query = query
      @chunk_size = chunk_size > 0 ? chunk_size : records.size
      paginate_response(records)
    end
    
    def paginate(records)
      return nil, records unless chunk_size
      paginate_response(records)
    end
    
    def self.get_chunk(token)
      raise NotImplementedError.new
    end

    protected 
    
    def paginate_response(records = [])
      raise NotImplementedError.new
    end
    
    def generate_tokens
      
    end  