module OAI
  
  class PartialResult
    attr_reader :records, :token
    
    def initialize(records, token = nil)
      @records = records
      @token = token
    end
    
  end

end