require 'test_helper'

class ActiveRecordProviderTest < TransactionalTestCase

  def test_identify
    assert @provider.identify =~ /ActiveRecord Based Provider/
  end

  def test_metadata_formats
    assert_nothing_raised { REXML::Document.new(@provider.list_metadata_formats) }
    doc =  REXML::Document.new(@provider.list_metadata_formats)
    assert doc.elements['/OAI-PMH/ListMetadataFormats/metadataFormat/metadataPrefix'].text == 'oai_dc'
  end

  def test_metadata_formats_for_record
    record_id = DCField.find(:first).id
    assert_nothing_raised { REXML::Document.new(@provider.list_metadata_formats(:identifier => "oai:test/#{record_id}")) }
    doc =  REXML::Document.new(@provider.list_metadata_formats)
    assert doc.elements['/OAI-PMH/ListMetadataFormats/metadataFormat/metadataPrefix'].text == 'oai_dc'
  end

  def test_list_records
    assert_nothing_raised do
      REXML::Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    end
    doc = REXML::Document.new(@provider.list_records(
      :metadata_prefix => 'oai_dc'))
    assert_equal 100, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_list_identifiers
    assert_nothing_raised { REXML::Document.new(@provider.list_identifiers) }
    doc = REXML::Document.new(@provider.list_identifiers)
    assert_equal 100, doc.elements['OAI-PMH/ListIdentifiers'].to_a.size
  end

  def test_get_record
    record_id = DCField.find(:first).id
    assert_nothing_raised do
      REXML::Document.new(@provider.get_record(
        :identifier => "oai:test/#{record_id}", :metadata_prefix => 'oai_dc'))
    end
    doc = REXML::Document.new(@provider.get_record(
      :identifier => "#{record_id}", :metadata_prefix => 'oai_dc'))
    assert_equal "oai:test/#{record_id}", doc.elements['OAI-PMH/GetRecord/record/header/identifier'].text
  end

  def test_deleted
    record = DCField.find(:first)
    record.deleted = true;
    record.save
    doc = REXML::Document.new(@provider.get_record(
      :identifier => "oai:test/#{record.id}", :metadata_prefix => 'oai_dc'))
    assert_equal "oai:test/#{record.id}", doc.elements['OAI-PMH/GetRecord/record/header/identifier'].text
    assert_equal 'deleted', doc.elements['OAI-PMH/GetRecord/record/header'].attributes["status"]
  end

  def test_from
    first_id = DCField.find(:first, :order => "id asc").id
    DCField.update_all(['updated_at = ?', Time.parse("January 1 2005")],
      "id < #{first_id + 90}")
    DCField.update_all(['updated_at = ?', Time.parse("June 1 2005")],
      "id < #{first_id + 10}")

    from_param = Time.parse("January 1 2006")

    doc = REXML::Document.new(
      @provider.list_records(
        :metadata_prefix => 'oai_dc', :from => from_param)
    )
    assert_equal DCField.find(:all, :conditions => ["updated_at >= ?", from_param]).size,
      doc.elements['OAI-PMH/ListRecords'].size

    doc = REXML::Document.new(
      @provider.list_records(
        :metadata_prefix => 'oai_dc', :from => Time.parse("May 30 2005"))
    )
    assert_equal 20, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_until
    first_id = DCField.find(:first, :order => "id asc").id
    DCField.update_all(['updated_at = ?', Time.parse("June 1 2005")],
      "id < #{first_id + 10}")

    doc = REXML::Document.new(
      @provider.list_records(
        :metadata_prefix => 'oai_dc', :until => Time.parse("June 1 2005"))
    )
    assert_equal 10, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_from_and_until
    first_id = DCField.find(:first, :order => "id asc").id
    DCField.update_all(['updated_at = ?', Time.parse("June 1 2005")])
    DCField.update_all(['updated_at = ?', Time.parse("June 15 2005")],
      "id < #{first_id + 50}")
    DCField.update_all(['updated_at = ?', Time.parse("June 30 2005")],
      "id < #{first_id + 10}")

    doc = REXML::Document.new(
      @provider.list_records(
        :metadata_prefix => 'oai_dc',
        :from => Time.parse("June 3 2005"),
        :until => Time.parse("June 16 2005"))
      )
    assert_equal 40, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_handles_empty_collections
    DCField.delete_all
    assert DCField.count == 0
    # Identify and ListMetadataFormats should return normally
    test_identify
    test_metadata_formats
    # ListIdentifiers and ListRecords should return "noRecordsMatch" error code
    assert_raises(OAI::NoMatchException) do
      REXML::Document.new(@provider.list_identifiers)
    end
    assert_raises(OAI::NoMatchException) do
      REXML::Document.new(@provider.list_records(:metadata_prefix => 'oai_dc'))
    end
  end

  def setup
    @provider = ARProvider.new
  end

end

class ActiveRecordProviderTimezoneTest < ActiveRecordProviderTest

  def setup
    require 'active_record'
    ActiveRecord::Base.default_timezone = :utc
    super
  end

  def teardown
    require 'active_record'
    ActiveRecord::Base.default_timezone = :local
    super
  end

end
