require 'test_helper'

class ActiveRecordProviderTest < Test::Unit::TestCase

  def test_identify
    assert @provider.identify =~ /ActiveRecord Based Provider/
  end
  
  def test_metadata_formats
    assert_nothing_raised { REXML::Document.new(@provider.list_metadata_formats) }
    doc =  REXML::Document.new(@provider.list_metadata_formats)
    assert doc.elements['/OAI-PMH/ListMetadataFormats/metadataFormat/metadataPrefix'].text == 'oai_dc'
  end
  
  def test_metadata_formats_for_record
    assert_nothing_raised { REXML::Document.new(@provider.list_metadata_formats(:identifier => 'oai:test/1')) }
    doc =  REXML::Document.new(@provider.list_metadata_formats)
    assert doc.elements['/OAI-PMH/ListMetadataFormats/metadataFormat/metadataPrefix'].text == 'oai_dc'
  end
  
  def test_list_records
    assert_nothing_raised { REXML::Document.new(@provider.list_records(:metadata_prefix => 'oai_dc')) }
    doc = REXML::Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_list_identifiers
    assert_nothing_raised { REXML::Document.new(@provider.list_identifiers(:metadata_prefix => 'oai_dc')) }
    doc = REXML::Document.new(@provider.list_identifiers(:metadata_prefix => 'oai_dc'))
    assert_equal 100, doc.elements['OAI-PMH/ListIdentifiers'].to_a.size
  end

  def test_get_record
    assert_nothing_raised { REXML::Document.new(@provider.get_record(:identifier => 'oai:test/1', :metadata_prefix => 'oai_dc')) }
    doc = REXML::Document.new(@provider.get_record(:identifier => 'oai:test/1', :metadata_prefix => 'oai_dc'))
    assert_equal 'oai:test/1', doc.elements['OAI-PMH/GetRecord/record/header/identifier'].text
  end
  
  def test_deleted
    DCField.update(5, :deleted => true)
    doc = REXML::Document.new(@provider.get_record(:identifier => 'oai:test/5', :metadata_prefix => 'oai_dc'))
    assert_equal 'oai:test/5', doc.elements['OAI-PMH/GetRecord/record/header/identifier'].text
    assert_equal 'deleted', doc.elements['OAI-PMH/GetRecord/record/header'].attributes["status"]
  end
  
  def test_from
    DCField.update_all(['updated_at = ?', Chronic.parse("January 1 2005")],
      "id < 90")
    DCField.update_all(['updated_at = ?', Chronic.parse("June 1 2005")],
      "id < 10")
    
    from_param = Chronic.parse("January 1 2006")
    
    doc = REXML::Document.new(
      @provider.list_records(:from => from_param, :metadata_prefix => 'oai_dc')
      )
    assert_equal DCField.find(:all, :conditions => ["updated_at >= ?", from_param]).size, 
      doc.elements['OAI-PMH/ListRecords'].size

    doc = REXML::Document.new(
      @provider.list_records(:from => Chronic.parse("May 30 2005"), :metadata_prefix => 'oai_dc')
      )
    assert_equal 20, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end
  
  def test_until
    DCField.update_all(['updated_at = ?', Chronic.parse("June 1 2005")],
      "id < 10")

    doc = REXML::Document.new(
      @provider.list_records(:until => Chronic.parse("June 1 2005"), 
      :metadata_prefix => 'oai_dc')
      )
    assert_equal 9, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end
  
  def test_from_and_until
    DCField.update_all(['updated_at = ?', Chronic.parse("June 1 2005")])
    DCField.update_all(['updated_at = ?', Chronic.parse("June 15 2005")],
      "id < 50")
    DCField.update_all(['updated_at = ?', Chronic.parse("June 30 2005")],
      "id < 10")

    doc = REXML::Document.new(
      @provider.list_records(:from => Chronic.parse("June 3 2005"),
        :until => Chronic.parse("June 16 2005"),
        :metadata_prefix => 'oai_dc')
      )
    assert_equal 40, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end
  
  def test_bad_identifer_raises_correct_exception
    assert_raise(OAI::IdException) do
      @provider.get_record( :identifier => "fjsdklf",
                            :metadataPrefix => "oai_dc")
    end
  end

  def setup
    @provider = ARProvider.new
    ARLoader.load
  end
  
  def teardown
    ARLoader.unload
  end
  
end
