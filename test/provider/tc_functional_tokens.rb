require 'test_helper'

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
    assert_equal 101, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_equal 101, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end

  def test_from_and_until_with_resumption_tokens
    # Should return 300 records broken into 3 groups of 100.
    assert_nothing_raised do
      Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    end
    doc = Document.new(
      @provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("September 1 2004"),
        :until => Time.parse("November 30 2004"))
      )
    assert_equal 101, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text

    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_equal 101, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text

    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_equal 100, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end

end