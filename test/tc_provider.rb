require 'rexml/document'
require File.dirname(__FILE__) + '/test_helper.rb'

class MappedProvider < OAI::Provider
  name 'Mapped Provider'
  prefix 'oai:test'
  model MappedModel
end

class SimpleProvider < OAI::Provider
  name 'Test Provider'
  prefix 'oai:test'
  model SimpleModel
end

class OaiTest < Test::Unit::TestCase

  def setup
    @simple_provider = SimpleProvider.new
    @mapped_provider = MappedProvider.new
  end
  
  def test_indentify
    doc = REXML::Document.new(@simple_provider.identify)
    assert doc.elements["/OAI-PMH/Identify/repositoryName"].text == 'Test Provider'
    assert doc.elements["/OAI-PMH/Identify/earliestDatestamp"].text == SimpleModel.oai_earliest.to_s
  end

  def test_list_sets
    doc = REXML::Document.new(@simple_provider.list_sets)
    sets = doc.elements["/OAI-PMH/ListSets"]
    assert sets.size == 2
    assert sets[0].elements["//setName"].text == "Test Set"
  end
  
  def test_metadata_formats
    assert_nothing_raised { REXML::Document.new(@simple_provider.list_metadata_formats) }
    doc =  REXML::Document.new(@simple_provider.list_metadata_formats)
    assert doc.elements['/OAI-PMH/ListMetadataFormats/metadataFormat/metadataPrefix'].text == 'oai_dc'
  end
  
  def test_list_records
    assert_nothing_raised { REXML::Document.new(@simple_provider.list_records) }
    doc = REXML::Document.new(@simple_provider.list_records)
    assert_equal 7, doc.elements['OAI-PMH/ListRecords'].to_a.size
    doc = REXML::Document.new(@simple_provider.list_records(:set => 'A'))
    assert_equal 7, doc.elements['OAI-PMH/ListRecords'].to_a.size
    doc = REXML::Document.new(@simple_provider.list_records(:set => 'A:B'))
    assert_equal 2, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_list_identifiers
    assert_nothing_raised { REXML::Document.new(@simple_provider.list_identifiers) }
    doc = REXML::Document.new(@simple_provider.list_identifiers)
    assert_equal 7, doc.elements['OAI-PMH/ListIdentifiers'].to_a.size
    doc = REXML::Document.new(@simple_provider.list_identifiers(:set => 'A'))
    assert_equal 7, doc.elements['OAI-PMH/ListIdentifiers'].to_a.size
    doc = REXML::Document.new(@simple_provider.list_identifiers(:set => 'A:B'))
    assert_equal 2, doc.elements['OAI-PMH/ListIdentifiers'].to_a.size
  end

  def test_get_record
    assert_nothing_raised { REXML::Document.new(@simple_provider.get_record('oai:test/1')) }
    doc = REXML::Document.new(@simple_provider.get_record('oai:test/1'))
    assert_equal 'oai:test/1', doc.elements['OAI-PMH/GetRecord/record/header/identifier'].text
  end
  
  def test_mapped_source
    assert_nothing_raised { REXML::Document.new(@mapped_provider.list_records) }
    doc = REXML::Document.new(@mapped_provider.list_records)
    assert_equal "title 1", doc.elements['OAI-PMH/ListRecords/record/metadata/oai_dc:dc/dc:creator'].text
    assert_equal "creator", doc.elements['OAI-PMH/ListRecords/record/metadata/oai_dc:dc/dc:title'].text
    assert_equal "tag 1", doc.elements['OAI-PMH/ListRecords/record/metadata/oai_dc:dc/dc:subject'].text
  end
  
  def test_verb_exception
    doc = REXML::Document.new(@simple_provider.process_verb('NoVerb'))
    assert doc.elements["/OAI-PMH/error"].attributes["code"] == 'badVerb'
  end
  
  def test_deleted
    assert_nothing_raised { REXML::Document.new(@simple_provider.get_record('oai:test/6')) }
    doc = REXML::Document.new(@simple_provider.get_record('oai:test/6'))
    assert_equal 'oai:test/6', doc.elements['OAI-PMH/GetRecord/record/header/identifier'].text
    assert_equal 'deleted', doc.elements['OAI-PMH/GetRecord/record/header'].attributes["status"]
  end
  
end
