# = paginator.rb
#
# Large response sets can be broken down into smaller sub documents thru the use
# of resumption tokens.
#
# Will Groppe mailto: wfg@artstor.org
#

module OAI
  
  class Paginator
    attr_reader :model, :chunk_size, :query, :last_requested
    
    def initialize(model, query, chunk_size = nil)
      @model = model
      @query = query
      @chunk_size = chunk_size
      requested
    end
    
    def paginate(records)
      requested
      return nil, records unless chunk_size
      paginate_response(records)
    end
    
    def self.get_chunk(token)
      requested
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