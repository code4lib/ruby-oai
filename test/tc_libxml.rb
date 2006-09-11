class LibXMLTest < Test::Unit::TestCase

  def test_get_record
    return unless have_libxml
    uri = 'http://www.pubmedcentral.gov/oai/oai.cgi'
    client = OAI::Client.new(uri, :parser => 'libxml')
    response = client.get_record :identifier => 'oai:pubmedcentral.gov:13901'
    assert_kind_of OAI::GetRecordResponse, response
    assert_kind_of OAI::Record, response.record
    assert_kind_of XML::Node, response.record.metadata
  end

  def atest_list_records
    return unless have_libxml
    uri = 'http://digitalcollections.library.oregonstate.edu/cgi-bin/oai.exe'
    client = OAI::Client.new uri, :parser => 'libxml'
    records = client.list_records(
      :set              => 'archives', 
      :metadata_prefix  => 'oai_dc', 
      :from             => Date.new(2006,8,1))
    records.each do |record|
      assert_match /oregonstate.edu:archives\/\d+$/, record.header.identifier
      assert_kind_of XML::Node, record.metadata
    end
  end

  private

  def have_libxml
    begin
      require 'xml/libxml'
      return true
    rescue
      return false
    end
  end

end
