require 'test_helper_ar_provider'

class CachingPagingProviderTest < TransactionalTestCase
  include REXML

  def test_full_harvest
    doc = Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].size
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].size
    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].size
    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end

  def test_from_and_until
    first_id = DCField.order(id: :asc).first.id
    DCField.where("dc_fields.id <= ?", first_id + 25).update_all(updated_at: Time.parse("September 15 2005"))
    DCField.where(["dc_fields.id < ? and dc_fields.id > ?", first_id + 50, first_id + 25]).update_all(updated_at: Time.parse("November 1 2005"))

    # Should return 50 records broken into 2 groups of 25.
    doc = Document.new(
      @provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("September 1 2005"),
        :until => Time.parse("November 30 2005"))
      )
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].size
    token = doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    doc = Document.new(@provider.list_records(:resumption_token => token))
    assert_not_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"]
    assert_nil doc.elements["/OAI-PMH/ListRecords/resumptionToken"].text
    assert_equal 26, doc.elements["/OAI-PMH/ListRecords"].to_a.size
  end

  def setup
    @provider = CachingResumptionProvider.new
  end

end
