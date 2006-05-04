module OAI

  # A class for representing a Record as returned from a GetRecord 
  # or ListRecords request. Each record will have a header and metadata
  # attribute. The header is a OAI::Header object and the metadata is 
  # a REXML::Element object for that chunk of XML. 
  
  class Record
    include OAI::XPath
    attr_accessor :header, :metadata

    def initialize(element)
      @header = OAI::Header.new xpath_first(element, './/header')
      @metadata = xpath_first(element, './/metadata')
    end
  end
end
