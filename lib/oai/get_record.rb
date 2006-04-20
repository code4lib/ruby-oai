module OAI
  class GetRecordResponse < Response
    include OAI::XPath
    attr_accessor :record

    def initialize(doc)
      super doc
      @record = OAI::Record.new(xpath_first(doc, './/record'))
    end
  end
end
