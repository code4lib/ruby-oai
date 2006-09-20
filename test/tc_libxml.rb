class LibXMLTest < Test::Unit::TestCase

  def test_oai_exception
    return unless have_libxml

    uri = 'http://www.pubmedcentral.gov/oai/oai.cgi'
    client = OAI::Client.new uri, :parser => 'libxml'
    assert_raises(OAI::Exception) {client.get_record(:identifier => 'nosuchid')}
  end

  def test_list_records
    return unless have_libxml

    # since there is regex magic going on to remove default oai namespaces 
    # it's worth trying a few different oai targets
    oai_targets = %w{
      http://etd.caltech.edu:80/ETD-db/OAI/oai
      http://ir.library.oregonstate.edu/dspace-oai/request
      http://libeprints.open.ac.uk/perl/oai2
      http://memory.loc.gov/cgi-bin/oai2_0
    }

    oai_targets.each do |uri|
      client = OAI::Client.new uri, :parser => 'libxml'
      records = client.list_records
      records.each do |record|
        assert record.header.identifier
        next unless record.deleted?
        assert_kind_of XML::Node, record.metadata
      end
    end
  end

  def test_deleted_record
    uri = 'http://ir.library.oregonstate.edu/dspace-oai/request'
    client = OAI::Client.new(uri, :parser => 'libxml')
    record = client.get_record :identifier => 'oai:ir.library.oregonstate.edu:1957/19' 
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
