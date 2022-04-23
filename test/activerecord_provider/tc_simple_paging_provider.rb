require 'test_helper_ar_provider'

class SimpleResumptionProviderTest < TransactionalTestCase
  include REXML

  def test_full_harvest
    doc = Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text

    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].to_a.size

    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].to_a.size

    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end

  def test_non_integer_identifiers_resumption
    @provider = SimpleResumptionProviderWithNonIntegerID.new

    doc = Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text

    next_doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil next_doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    next_token = next_doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_equal 26, next_doc.elements["/OAI-PMH/ListRecords"].to_a.size

    assert_not_equal token, next_token
  end

  def test_from_and_until
    first_id = DCField.order("id asc").first.id
    DCField.where("dc_fields.id < ?", first_id + 25).update_all(updated_at: Time.parse("September 15 2005"))
    DCField.where(["dc_fields.id <= ? and dc_fields.id > ?", first_id + 50, first_id + 25]).update_all(updated_at: Time.parse("November 1 2005"))

    total = DCField.where(["dc_fields.updated_at >= ? AND dc_fields.updated_at <= ?", Time.parse("September 1 2005"), Time.parse("November 30 2005")]).count

    # Should return 50 records broken into 2 groups of 25.
    doc = Document.new(
      @provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("September 1 2005"),
        :until => Time.parse("November 30 2005"))
      )
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].to_a.size
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end

  def setup
    @provider = SimpleResumptionProvider.new
  end

end
