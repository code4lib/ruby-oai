class ResumptionTokenTest < Test::Unit::TestCase
  include REXML
  
  def setup
    @provider = ComplexProvider.new
  end

  def test_resumption_tokens
    assert_nothing_raised { Document.new(@provider.list_records) }
    doc = Document.new(@provider.list_records)
    assert_not_nil doc.elements["/OAI-PMH/resumptionToken"]
    assert_equal 100, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/resumptionToken"].text
    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/resumptionToken"]
    assert_equal 100, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end

  def test_from_and_until_with_resumption_tokens
    # Should return 300 records broken into 3 groups of 100.
    assert_nothing_raised { Document.new(@provider.list_records) }
    doc = Document.new(
      @provider.list_records(
        :from => Chronic.parse("September 1 2004"),
        :until => Chronic.parse("November 30 2004"))
      )
    assert_equal 100, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/resumptionToken"].text
  
    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/resumptionToken"]
    assert_equal 100, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/resumptionToken"].text

    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_nil doc.elements["/OAI-PMH/resumptionToken"]
    assert_equal 100, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end
  
  def test_resumption_token_empty
    doc = Document.new(@provider.list_records)
    assert_equal 'oai_dc.f(1998-05-02T16:00:00Z).u(2005-12-25T17:00:00Z):1', 
      doc.elements['OAI-PMH/resumptionToken'].text
  end
  
  def test_resumption_token_with_set
    docs = Document.new(@provider.list_records(:set => 'Four'))
    assert_equal "oai_dc.s(Four).f(1998-05-02T16:00:00Z).u(2005-12-25T17:00:00Z):1",
      docs.elements['OAI-PMH/resumptionToken'].text
  end

  def test_resumption_token_with_from
    docs = Document.new(@provider.list_records(:from => 
      Chronic.parse("November 1 2000")
      )
    )
    assert_equal "oai_dc.f(2000-11-01T17:00:00Z).u(2005-12-25T17:00:00Z):1",
      docs.elements['OAI-PMH/resumptionToken'].text
  end

  def test_resumption_token_with_until
    docs = Document.new(@provider.list_records(:until => 
      Chronic.parse("November 30 2006")
      )
    )
    assert_equal "oai_dc.f(1998-05-02T16:00:00Z).u(2006-11-30T17:00:00Z):1",
      docs.elements['OAI-PMH/resumptionToken'].text
  end

  def test_resumption_token_with_from_and_until
    docs = Document.new(@provider.list_records(
      :from => Chronic.parse("November 1 2000"),
      :until => Chronic.parse("November 30 2006")
      )
    )
    assert_equal "oai_dc.f(2000-11-01T17:00:00Z).u(2006-11-30T17:00:00Z):1",
      docs.elements['OAI-PMH/resumptionToken'].text
  end

  def test_resumption_token_with_set_from_until
    docs = Document.new(@provider.list_records(
      :set => 'Three:Four',
      :from => Chronic.parse("November 1 2000"),
      :until => Chronic.parse("November 30 2006")
      )
    )
    assert_equal "oai_dc.s(Three:Four).f(2000-11-01T17:00:00Z).u(2006-11-30T17:00:00Z):1",
      docs.elements['OAI-PMH/resumptionToken'].text
  end
  
end