module OAI
  class Record
    include OAI::XPath
    attr_accessor :header, :metadata

    def initialize(element)
      @header = OAI::Header.new xpath_first(element, './/header')
      @metadata = xpath_first(element, './/metadata')
    end
  end
end
