module OAI
  class Response
    include OAI::XPath
    attr_reader :doc, :resumption_token

    def initialize(doc)
      @doc = doc
      @resumption_token = xpath(doc, './/resumptionToken')

      # throw an exception if there was an error
      error = xpath_first(doc, './/error')
      if error
        message = error.text
        code = error.attributes['code']
        raise OAI::Exception.new("#{message} [#{code}]")
      end
    end

  end
end
