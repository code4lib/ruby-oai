class GetRecordTest < Test::Unit::TestCase
  def test_get_one
    client = OAI::Client.new 'http://www.pubmedcentral.gov/oai/oai.cgi'
    response = client.get_record :identifier => 'oai:pubmedcentral.gov:13901'
    assert_kind_of OAI::GetRecordResponse, response
    assert_kind_of OAI::Record, response.record
    assert_kind_of REXML::Element, response.record.metadata
    assert_kind_of OAI::Header, response.record.header

    # minimal check that the header is working
    assert_equal 'oai:pubmedcentral.gov:13901', 
      response.record.header.identifier

    # minimal check that the metadata is working
    assert 'en', response.record.metadata.elements['.//dc:language'].text
  end

  def test_missing_identifier
    client = OAI::Client.new 'http://www.pubmedcentral.gov/oai/oai.cgi'
    begin
      client.get_record :metadata_prefix => 'oai_dc'
      flunk 'invalid get_record did not throw OAI::Exception'
    rescue OAI::Exception => e
      assert_match /The request includes illegal arguments/, e.to_s
    end
  end
end
