class OaiTest < Test::Unit::TestCase

  def setup
    @simple_provider = SimpleProvider.new
    @mapped_provider = MappedProvider.new
    @big_provider = BigProvider.new
    @token_provider = TokenProvider.new
  end
  
  def test_indentify
    doc = REXML::Document.new(@simple_provider.identify)
    assert doc.elements["/OAI-PMH/Identify/repositoryName"].text == 'Test Provider'
    assert doc.elements["/OAI-PMH/Identify/earliestDatestamp"].text == SimpleModel.new.oai_earliest.to_s
  end

  def test_list_sets
    doc = REXML::Document.new(@simple_provider.list_sets)
    sets = doc.elements["/OAI-PMH/ListSets"]
    assert sets.size == 2
    assert sets[0].elements["//setName"].text == "Test Set One"
  end
  
  def test_metadata_formats
    assert_nothing_raised { REXML::Document.new(@simple_provider.list_metadata_formats) }
    doc =  REXML::Document.new(@simple_provider.list_metadata_formats)
    assert doc.elements['/OAI-PMH/ListMetadataFormats/metadataFormat/metadataPrefix'].text == 'oai_dc'
  end
  
  def test_list_records
    assert_nothing_raised { REXML::Document.new(@simple_provider.list_records) }
    doc = REXML::Document.new(@simple_provider.list_records)
    assert_equal 10, doc.elements['OAI-PMH/ListRecords'].to_a.size
    doc = REXML::Document.new(@simple_provider.list_records(:set => 'A'))
    assert_equal 5, doc.elements['OAI-PMH/ListRecords'].to_a.size
    doc = REXML::Document.new(@simple_provider.list_records(:set => 'A:B'))
    assert_equal 5, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_list_identifiers
    assert_nothing_raised { REXML::Document.new(@simple_provider.list_identifiers) }
    doc = REXML::Document.new(@simple_provider.list_identifiers)
    assert_equal 10, doc.elements['OAI-PMH/ListIdentifiers'].to_a.size
    doc = REXML::Document.new(@simple_provider.list_identifiers(:set => 'A'))
    assert_equal 5, doc.elements['OAI-PMH/ListIdentifiers'].to_a.size
    doc = REXML::Document.new(@simple_provider.list_identifiers(:set => 'A:B'))
    assert_equal 5, doc.elements['OAI-PMH/ListIdentifiers'].to_a.size
  end

  def test_get_record
    assert_nothing_raised { REXML::Document.new(@simple_provider.get_record('oai:test/1')) }
    doc = REXML::Document.new(@simple_provider.get_record('oai:test/1'))
    assert_equal 'oai:test/1', doc.elements['OAI-PMH/GetRecord/record/header/identifier'].text
  end
  
  def test_mapped_source
    assert_nothing_raised { REXML::Document.new(@mapped_provider.list_records) }
    doc = REXML::Document.new(@mapped_provider.list_records)
    assert_equal "title_0", doc.elements['OAI-PMH/ListRecords/record/metadata/oai_dc:dc/dc:creator'].text
    assert_equal "creator_0", doc.elements['OAI-PMH/ListRecords/record/metadata/oai_dc:dc/dc:title'].text
    assert_equal "tag_0", doc.elements['OAI-PMH/ListRecords/record/metadata/oai_dc:dc/dc:subject'].text
  end
  
  def test_verb_exception
    doc = REXML::Document.new(@simple_provider.process_verb('NoVerb'))
    assert doc.elements["/OAI-PMH/error"].attributes["code"] == 'badVerb'
  end
  
  def test_deleted
    assert_nothing_raised { REXML::Document.new(@simple_provider.get_record('oai:test/6')) }
    doc = REXML::Document.new(@simple_provider.get_record('oai:test/5'))
    assert_equal 'oai:test/5', doc.elements['OAI-PMH/GetRecord/record/header/identifier'].text
    assert_equal 'deleted', doc.elements['OAI-PMH/GetRecord/record/header'].attributes["status"]
  end
  
  def test_from
    assert_nothing_raised { REXML::Document.new(@big_provider.list_records) }
    doc = REXML::Document.new(
      @big_provider.list_records(:from => Chronic.parse("February 1 2001"))
      )
    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size

    doc = REXML::Document.new(
      @big_provider.list_records(:from => Chronic.parse("January 1 2001"))
      )
    assert_equal 200, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end
  
  def test_until
    assert_nothing_raised { REXML::Document.new(@big_provider.list_records) }
    doc = REXML::Document.new(
      @big_provider.list_records(:until => Chronic.parse("November 1 2000"))
      )
    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end
  
  def test_from_and_until
    assert_nothing_raised { REXML::Document.new(@big_provider.list_records) }
    doc = REXML::Document.new(
      @big_provider.list_records(:from => Chronic.parse("November 1 2000"),
        :until => Chronic.parse("November 30 2000"))
      )
    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size

    doc = REXML::Document.new(
      @big_provider.list_records(:from => Chronic.parse("December 1 2000"),
      :until => Chronic.parse("December 31 2000"))
      )
    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end
  
  def test_resumption_tokens
    #assert_nothing_raised { REXML::Document.new(@token_provider.list_records) }
    doc = REXML::Document.new(@token_provider.list_records)
    assert_not_nil doc.elements["/OAI-PMH/resumptionToken"]
    assert_equal 25, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/resumptionToken"].text
    doc = REXML::Document.new(@token_provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/resumptionToken"]
    assert_equal 25, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end

  def test_from_and_until_with_resumption_tokens
    # Should return 100 records broken into 4 groups of 25.
    assert_nothing_raised { REXML::Document.new(@token_provider.list_records) }
    doc = REXML::Document.new(
      @token_provider.list_records(:from => Chronic.parse("November 1 2000"),
        :until => Chronic.parse("November 30 2000"))
      )
    assert_equal 25, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/resumptionToken"].text
    
    doc = REXML::Document.new(@token_provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/resumptionToken"]
    assert_equal 25, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/resumptionToken"].text

    doc = REXML::Document.new(@token_provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/resumptionToken"]
    assert_equal 25, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/resumptionToken"].text

    doc = REXML::Document.new(@token_provider.list_records(:resumption_token => token))
    assert_nil doc.elements["/OAI-PMH/resumptionToken"]
    assert_equal 25, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end
    
end
