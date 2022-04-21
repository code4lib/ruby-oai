require 'test_helper_provider'

class ResumptionTokenFunctionalTest < Test::Unit::TestCase
  include REXML

  def setup
    @provider = ComplexProvider.new
    @provider.model.instance_variable_set(:@limit, 120)
  end

  def teardown
    @provider.model.instance_variable_set(:@limit, 100)
  end

  def test_resumption_tokens
    assert_nothing_raised do
      Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    end
    doc = Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_equal (@provider.model.limit + 1), doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_equal (@provider.model.limit + 1), doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end

  def test_from_and_until_with_resumption_tokens
    # Should return 300 records broken into 3 groups of 120, 120, and 60.
    assert_nothing_raised do
      Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    end
    doc = Document.new(
      @provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("September 1 2004"),
        :until => Time.parse("November 30 2004"))
      )
    assert_equal (@provider.model.limit + 1), doc.elements["/OAI-PMH/ListRecords"].to_a.size
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text

    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_equal (@provider.model.limit + 1), doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text

    doc = Document.new(@provider.list_records(:resumption_token => token))
    # assert that ListRecords includes remaining records and an empty resumption token
    assert_equal (301 % @provider.model.limit), doc.elements["/OAI-PMH/ListRecords"].to_a.size
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
  end

end
