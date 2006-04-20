class ListSetsTest < Test::Unit::TestCase

  def test_list
    client = OAI::Client.new 'http://www.pubmedcentral.gov/oai/oai.cgi'
    response = client.list_sets
    assert_kind_of OAI::ListSetsResponse, response
    assert response.entries.size > 0
    assert_kind_of OAI::Set,  response.entries[0]
  
    # test iterator
    for set in response
      assert_kind_of OAI::Set, set
    end
  end

end

