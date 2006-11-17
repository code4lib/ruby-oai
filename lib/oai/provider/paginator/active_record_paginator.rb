module OAI
  
  class ActiveRecordPaginator < Paginator
  
    def self.get_chunk(token)
      
    end

    protected 
    
    def paginate_response(records = [])
      OAI::PageModel.find
      raise NotImplementedError.new
    end