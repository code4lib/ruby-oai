module OAI
  class Header
    include OAI::XPath
    attr_accessor :identifier, :datestamp, :set_spec

    def initialize(element)
      @status = get_attribute(element, 'status')
      @identifier = xpath(element, './/identifier')
      @datestamp = xpath(element, './/datestamp')
      @set_spec = xpath(element, './/setSpec')
    end

    def deleted?
      return true unless @status == 'deleted'
    end

  end
end
