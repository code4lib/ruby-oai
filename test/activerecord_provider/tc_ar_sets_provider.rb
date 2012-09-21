require 'test_helper'

class ActiveRecordSetProviderTest < TransactionalTestCase

  def test_list_sets
    doc = REXML::Document.new(@provider.list_sets)
    sets = doc.elements["/OAI-PMH/ListSets"]
    assert sets.size == 4
    assert sets[0].elements["//setName"].text == "Set A"
  end

  def test_set_a
    doc = REXML::Document.new(@provider.list_records(
      :metadata_prefix => 'oai_dc', :set => "A"))
    assert_equal 20, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_set_b
    doc = REXML::Document.new(@provider.list_records(
      :metadata_prefix => 'oai_dc', :set => "B"))
    assert_equal 10, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_set_ab
    doc = REXML::Document.new(@provider.list_records(
      :metadata_prefix => 'oai_dc', :set => "A:B"))
    assert_equal 10, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_record_with_multiple_sets
    record = DCSet.find(:first, :conditions => "spec = 'C'").dc_fields.first
    assert_equal 2, record.sets.size
  end

  def test_missing_set
    assert_raise(OAI::NoMatchException) do
      doc = REXML::Document.new(@provider.list_records(
        :metadata_prefix => 'oai_dc', :set => "D"))
    end
  end

  def setup
    @provider = ARSetProvider.new
    define_sets
  end

  def define_sets
    set_a = DCSet.create(:name => "Set A", :spec => "A")
    set_b = DCSet.create(:name => "Set B", :spec => "B")
    set_c = DCSet.create(:name => "Set C", :spec => "C")
    set_ab = DCSet.create(:name => "Set A:B", :spec => "A:B")

    next_id = 0
    DCField.find(:all, :limit => 10, :order => "id asc").each do |record|
      set_a.dc_fields << record
      next_id = record.id
    end

    DCField.find(:all, :limit => 10, :order => "id asc", :conditions => "id > #{next_id}").each do |record|
      set_b.dc_fields << record
      next_id = record.id
    end

    DCField.find(:all, :limit => 10, :order => "id asc", :conditions => "id > #{next_id}").each do |record|
      set_ab.dc_fields << record
      next_id = record.id
    end

    DCField.find(:all, :limit => 10, :order => "id asc", :conditions => "id > #{next_id}").each do |record|
      set_a.dc_fields << record
      set_c.dc_fields << record
      next_id = record.id
    end
  end
end


class ActiveRecordExclusiveSetsProviderTest < TransactionalTestCase

  def test_list_sets
    doc = REXML::Document.new(@provider.list_sets)
    sets = doc.elements["/OAI-PMH/ListSets"]
    assert_equal 3, sets.size
    assert_equal "Set A", sets[0].elements["//setName"].text
  end

  def test_set_a
    doc = REXML::Document.new(@provider.list_records(
      :metadata_prefix => 'oai_dc', :set => "A"))
    assert_equal 20, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_set_b
    doc = REXML::Document.new(@provider.list_records(
      :metadata_prefix => 'oai_dc', :set => "B"))
    assert_equal 10, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_set_ab
    doc = REXML::Document.new(@provider.list_records(
      :metadata_prefix => 'oai_dc', :set => "A:B"))
    assert_equal 10, doc.elements['OAI-PMH/ListRecords'].to_a.size
  end

  def test_missing_set
    assert_raise(OAI::NoMatchException) do
      doc = REXML::Document.new(@provider.list_records(
        :metadata_prefix => 'oai_dc', :set => "D"))
    end
  end

  def setup
    @provider = ARExclusiveSetProvider.new
    define_sets
  end

  def define_sets
    next_id = 0

    ExclusiveSetDCField.find(:all, :limit => 10, :order => "id asc").each do |record|
      record.set = "A"
      record.save!
      next_id = record.id
    end

    ExclusiveSetDCField.find(:all, :limit => 10, :order => "id asc", :conditions => "id > #{next_id}").each do |record|
      record.set = "B"
      record.save!
      next_id = record.id
    end

    ExclusiveSetDCField.find(:all, :limit => 10, :order => "id asc", :conditions => "id > #{next_id}").each do |record|
      record.set = "A:B"
      record.save!
      next_id = record.id
    end

    ExclusiveSetDCField.find(:all, :limit => 10, :order => "id asc", :conditions => "id > #{next_id}").each do |record|
      record.set = "A"
      record.save!
      next_id = record.id
    end
  end

  protected

  def load_fixtures
    fixtures = YAML.load_file(
      File.join(File.dirname(__FILE__), 'fixtures', 'dc.yml')
    )
    disable_logging do
      fixtures.keys.sort.each do |key|
        ExclusiveSetDCField.create(fixtures[key])
      end
    end
  end

end