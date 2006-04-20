require 'rexml/xpath'

module OAI
  module XPath
    def xpath_all(doc, path)
      return REXML::XPath.match(doc, path)
    end

    def xpath_first(doc, path)
      elements = xpath_all(doc, path)
      return elements[0] if elements != nil
      return nil
    end

    def xpath(doc, path)
      e = xpath_first(doc, path)
      return e.text if e != nil
      return nil
    end
  end
end
