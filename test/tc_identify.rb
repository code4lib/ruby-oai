class IdentifyTest < Test::Unit::TestCase
  def test_ok
    client = OAI::Client.new 'http://www.pubmedcentral.gov/oai/oai.cgi'
    response = client.identify
    assert_kind_of OAI::IdentifyResponse, response
    assert_equal 'PubMed Central (PMC3 - NLM DTD) [http://www.pubmedcentral.nih.gov:80/oai/oai.cgi]', response.to_s
  end
end
