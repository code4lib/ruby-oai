module OAI
  module XPath
    def xpath_all(doc, path)
      case $parser
	 when 'libxml'
	    require 'rubygems'
	    require 'xml/libxml'
	    return doc.find( path)
	 else
	    require 'rexml/xpath'
            return REXML::XPath.match(doc, path)
       end
    end

    def xpath_first(doc, path)
      elements = xpath_all(doc, path)
      return elements[0] if elements != nil
      return nil
    end

    def xpath(doc, path)
      e = xpath_first(doc, path)
      case $parser
	when 'libxml'
	  begin
	     return e.content
          rescue
	     return nil
	  end
        else
	  return e.text if e != nil
	  return nil
       end  
    end
  end
end
