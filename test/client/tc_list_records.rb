require 'test_helper'

class ListRecordsTest < Test::Unit::TestCase

  def test_list
    client = OAI::Client.new 'http://localhost:3333/oai'
    response = client.list_records
    assert_kind_of OAI::ListRecordsResponse, response
    assert response.entries.size > 0
    assert_kind_of OAI::Record,  response.entries[0]
  end

  def test_list_full
    client = OAI::Client.new 'http://localhost:3333/oai'

    response = client.list_records
    assert_kind_of OAI::ListRecordsResponse, response

    # Check that it runs through the pages
    assert_equal 1150, response.full.count
    response.full.each do |record|
      assert_kind_of OAI::Record, record
    end
  end

end
