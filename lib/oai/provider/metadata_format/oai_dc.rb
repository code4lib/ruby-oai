# = OaiPmh::Metadata::OaiDc
#
# Copyright (C) 2006 William Groppe
#
# Will Groppe mailto:wfg@artstor.org
#
# Only one form of metadata is supported out of the box.  Dublin Core is the 
# most basic form of metadata, and the one recommended for support in all
# OAI-PMH repositories.
#
# To add additional metadata types it's easiest just to subclass 
# Oai::Metadata::OaiDc.  Subclasses should override header(xml) to ouput a 
# valid metadata header.  They should also set defaults for prefix, schema,
# namespace, element_ns, and fields.
#
# === Example
#  class CdwaLite < Oai::Metadata::OaiDc
#    prefix = 'cdwalite'
#    schema = 'http://www.getty.edu/CDWA/CDWALite/CDWALite-xsd-draft-009c2.xsd'
#    namespace = 'http://www.getty.edu/CDWA/CDWALite'
#    element_ns = 'cdwalite'
#    fields = [] # using to_cdwalite in model
#
#    def self.header(xml)
#      xml.tag!('cdwalite:cdwalite',
#       'xmlns:cdwalite' => "http://www.getty.edu/CDWA/CDWALite",
#       'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
#       'xsi:schemaLocation' => 
#         %{http://www.getty.edu/CDWA/CDWALite 
#           http://www.getty.edu/CDWA/CDWALite/CDWALite-xsd-draft-009c2.xsd}) do
#         yield xml
#      end
#    end
#  end
#
#  # Now register the new metadata class
#  Oai.register_metadata_class(CdwaLite)
#
module OAI::Metadata

  class DublinCore < MetadataFormat
    
    def initialize
      @prefix = 'oai_dc'
      @schema = 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
      @namespace = 'http://www.openarchives.org/OAI/2.0/oai_dc/'
      @element_namespace = 'dc'
      @fields = [ :title, :creator, :subject, :description, :publisher,
                  :contributor, :date, :type, :format, :identifier,
                  :source, :language, :relation, :coverage, :rights]
    end

    def header_specification
      {
        'xmlns:oai_dc' => "http://www.openarchives.org/OAI/2.0/oai_dc/",
        'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xsi:schemaLocation' => 
          %{http://www.openarchives.org/OAI/2.0/oai_dc/ 
            http://www.openarchives.org/OAI/2.0/oai_dc.xsd}            
      }
    end

  end
end