require 'thread'

module OAI
  
  module Paginate
    
    class Entry
      attr_accessor :data, :expiration
      
      def initialize(data, expiration = nil)
        @data = data
        @expiration = expiration
      end
      
      def size
        @data.size if @data && @data.respond_to?(:size)
      end
      
      def chunk(index)
        @data[index]
      end
      
    end
    
  end

  class SimplePaginator < Paginator
  
    CACHE = {}
    
    def initialize(chunk_size = 25)
      super(chunk_size)
      @mutex = Mutex.new
    end
  
    def get_chunk(token)
      begin
        query, num = token.split(/:/)
        index = num.to_i
        if index < CACHE[query].size
          return CACHE[query].chunk(index), "#{query}:#{(index)+1}"
        else
          return CACHE[query].chunk(index), nil
        end
      rescue
        raise ResumptionTokenException.new
      end
    end

    def query_cached?(query)
      #sweep_cache
      CACHE.keys.include?(query)
    end

    protected 
    
    def paginate_response(query, records = [])
      return nil, nil if records.empty?
      
      unless query_cached?(query)
        groups = generate_chunks(records)
        @mutex.synchronize do
          CACHE[query] = OAI::Paginate::Entry.new(groups)
        end
      end
      
      if records.size > @chunk_size
        return CACHE[query].chunk(0), "#{query}:1"
      else
        return CACHE[query].chunk(0), nil
      end
      
    end
    
    private
    
    def sweep_cache
      now = Time.now.utc
      CACHE.keys.each do |key|
        entry = CACHE[key]
        if entry.expiration && entry.expiration < now
          @mutex.synchronize do
            CACHE.delete(key)
          end
        end
      end
    end
    
  end
  
end