require 'test_helper'

class ListSetsTest < Test::Unit::TestCase

  def test_list
    client = OAI::Client.new 'http://localhost:3333/oai'
    response = client.list_sets
    assert_kind_of OAI::ListSetsResponse, response
    assert response.entries.size > 0
    assert_kind_of OAI::Set,  response.entries[0]

    # test iterator
    for set in response
      assert_kind_of OAI::Set, set
    end
  end

  def test_list_full
    client = OAI::Client.new 'http://localhost:3333/oai'

    response = client.list_sets
    assert_kind_of OAI::ListSetsResponse, response
    assert_kind_of OAI::Response, response
    assert response.respond_to?(:full), "Should expose :full"

    # This won't page, but it should work anyway
    assert_equal 6, response.full.count
    response.full.each do |set|
      assert_kind_of OAI::Set, set
    end
  end

end

