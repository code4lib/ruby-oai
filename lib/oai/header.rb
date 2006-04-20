module OAI
  class Header
    include OAI::XPath
    attr_accessor :identifier, :datestamp, :set_spec

    def initialize(element)
      @identifier = xpath(element, './/identifier')
      @datestamp = xpath(element, './/datestamp')
      @set_spec = xpath(element, './/setSpec')
    end
  end
end
