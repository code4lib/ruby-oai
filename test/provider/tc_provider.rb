require 'test_helper'

class OaiTest < Test::Unit::TestCase

  def setup
    @mapped_provider = MappedProvider.new
    @big_provider = BigProvider.new
    @described_provider = DescribedProvider.new
  end

  def test_additional_description
    doc = REXML::Document.new(@described_provider.identify)
    assert_equal "oai:test:13900", doc.elements['OAI-PMH/Identify/description/oai-identifier/sampleIdentifier'].text
    assert_not_nil doc.elements['OAI-PMH/Identify/my_custom_xml']
  end

  def test_list_identifiers_for_correct_xml
    doc = REXML::Document.new(@mapped_provider.list_identifiers)
    assert_not_nil doc.elements['OAI-PMH/request']
    assert_not_nil doc.elements['OAI-PMH/request/@verb']
    assert_not_nil doc.elements['OAI-PMH/ListIdentifiers']
    assert_not_nil doc.elements['OAI-PMH/ListIdentifiers/header']
    assert_not_nil doc.elements['OAI-PMH/ListIdentifiers/header/identifier']
    assert_not_nil doc.elements['OAI-PMH/ListIdentifiers/header/datestamp']
    assert_not_nil doc.elements['OAI-PMH/ListIdentifiers/header/setSpec']
  end

  def test_list_records_for_correct_xml
    doc = REXML::Document.new(
      @mapped_provider.list_records(:metadata_prefix => 'oai_dc'))
    assert_not_nil doc.elements['OAI-PMH/request']
    assert_not_nil doc.elements['OAI-PMH/request/@verb']
    assert_not_nil doc.elements['OAI-PMH/request/@metadata_prefix']
    assert_not_nil doc.elements['OAI-PMH/ListRecords/record/header']
    assert_not_nil doc.elements['OAI-PMH/ListRecords/record/metadata']
  end

  def test_mapped_source
    assert_nothing_raised do
      REXML::Document.new(
        @mapped_provider.list_records(:metadata_prefix => 'oai_dc'))
    end
    doc = REXML::Document.new(
      @mapped_provider.list_records(:metadata_prefix => 'oai_dc'))
    assert_equal "title_0", doc.elements['OAI-PMH/ListRecords/record/metadata/oai_dc:dc/dc:creator'].text
    assert_equal "creator_0", doc.elements['OAI-PMH/ListRecords/record/metadata/oai_dc:dc/dc:title'].text
    assert_equal "tag_0", doc.elements['OAI-PMH/ListRecords/record/metadata/oai_dc:dc/dc:subject'].text
  end

  def test_from
    assert_nothing_raised do
      REXML::Document.new(
        @big_provider.list_records(:metadata_prefix => 'oai_dc'))
    end
    doc = REXML::Document.new(
      @big_provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("February 1 2001"))
    )
    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size

    doc = REXML::Document.new(
      @big_provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("January 1 2001"))
    )
    assert_equal 200, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_until
    assert_nothing_raised do
      REXML::Document.new(
        @big_provider.list_records(:metadata_prefix => 'oai_dc'))
    end
    doc = REXML::Document.new(
      @big_provider.list_records(
        :metadata_prefix => 'oai_dc', :until => Time.parse("November 1 2000"))
    )
    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end
  
  def test_from_and_until_match
    assert_nothing_raised do
      @big_provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => "2000-11-01T05:00:00Z",
        :until =>  "2000-11-30T05:00:00Z"
      )
    end
    
    assert_nothing_raised do
      @big_provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => "2000-11-01",
        :until =>  "2000-11-30"
      )
    end
    
    assert_raise(OAI::ArgumentException) do
      @big_provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => "2000-11-01T05:00:00Z",
        :until =>  "2000-11-30"
      )
    end
  end

  def test_from_and_until
    assert_nothing_raised do
      REXML::Document.new(
        @big_provider.list_records(:metadata_prefix => 'oai_dc'))
    end
    doc = REXML::Document.new(
      @big_provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("November 1 2000"),
        :until => Time.parse("November 30 2000"))
    )

    assert_not_nil doc.elements['OAI-PMH/request']
    assert_not_nil doc.elements['OAI-PMH/request/@verb']
    assert_not_nil doc.elements['OAI-PMH/request/@from']
    assert_not_nil doc.elements['OAI-PMH/request/@until']

    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size

    doc = REXML::Document.new(
      @big_provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("December 1 2000"),
        :until => Time.parse("December 31 2000"))
    )
    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

end
