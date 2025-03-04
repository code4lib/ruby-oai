require 'test_helper_client'

class LowResolutionDatesTest < Test::Unit::TestCase

  def test_low_res_date_parsing
    client = OAI::Client.new 'http://localhost:3333/oai'

    date = Date.new 2003, 1, 1

    # get a list of identifier headers
    assert_nothing_raised { client.list_identifiers :from => date }
  end

end
