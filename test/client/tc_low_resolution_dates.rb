require 'test_helper_client'

class LowResolutionDatesTest < Test::Unit::TestCase

  # We really should not be testing against a live OAI server, come on!
  # It could go away!  But I'm not sure how to make this test reasonable,
  # what it's really testing.
  def test_low_res_date_parsing
    client = OAI::Client.new 'http://authors.library.caltech.edu/oai2d'

    date = Date.new 2003, 1, 1

    # get a list of identifier headers
    assert_nothing_raised { client.list_identifiers :from => date }
  end

end
