require 'test_helper_provider'

class ResumptionTokenFunctionalTest < Test::Unit::TestCase
  include REXML

  def setup
    @provider = ComplexProvider.new
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
    # Should return 550 records broken into 5 groups of 100, and a final group of 50.
    # checked elements under ListRecords are limit + 1, accounting for the resumptionToken element
    assert_nothing_raised do
      Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    end
    doc = Document.new(
      @provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("September 1 2004"),
        :until => Time.parse("December 25 2005"))
      )
    assert_equal (@provider.model.limit + 1), doc.elements["/OAI-PMH/ListRecords"].to_a.size
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text

    4.times do
      doc = Document.new(@provider.list_records(:resumption_token => token))
      assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
      assert_equal (@provider.model.limit + 1), doc.elements["/OAI-PMH/ListRecords"].to_a.size
      token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    end

    doc = Document.new(@provider.list_records(:resumption_token => token))
    # assert that ListRecords includes remaining records and an empty resumption token
    assert_equal (551 % @provider.model.limit), doc.elements["/OAI-PMH/ListRecords"].to_a.size
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
  end

end
