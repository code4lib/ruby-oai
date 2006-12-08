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
  
    def initialize(page_size = 25)
      super(page_size)
      @cache = {}
      @mutex = Mutex.new
    end
  
    def get_chunk(token)
      begin
        query, num = token.split(/:/)
        index = num.to_i
        if index < (@cache[query].size - 1)
          return @cache[query].chunk(index), "#{query}:#{(index)+1}"
        else
          return @cache[query].chunk(index), nil
        end
      rescue
        raise ResumptionTokenException.new
      end
    end

    def query_cached?(query)
      #sweep_cache
      @cache.keys.include?(query)
    end

    protected 
    
    def paginate_response(query, records = [])
      return nil, nil if records.empty?
      
      unless query_cached?(query)
        groups = generate_chunks(records)
        @mutex.synchronize do
          @cache[query] = OAI::Paginate::Entry.new(groups)
        end
      end
      
      if records.size > chunk_size
        return @cache[query].chunk(0), "#{query}:1"
      else
        return @cache[query].chunk(0), nil
      end
      
    end
    
    private
    
    def sweep_cache
      now = Time.now.utc
      @cache.keys.each do |key|
        entry = @cache[key]
        if entry.expiration && entry.expiration < now
          @mutex.synchronize do
            @cache.delete(key)
          end
        end
      end
    end
    
  end
  
end