module OAI

  class SimplePaginator < Paginator
  
    CACHE = {}
  
    def self.get_chunk(token)
      query, index = token.split(/:/)
      return "#{query}:#{index+1}", CACHE[query][index]
    end

    protected 
    
    def paginate_response(records = [])
      unless CACHE.keys.include?(@query)
        groups = generate_chunks(records)
        CACHE[@query] = groups
      end
      return "#{@query}:1", CACHE[@query][0]
    end
    
  end
  
end