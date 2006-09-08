#require 'rexml/element'
require 'oai'

client = OAI::Client.new 'http://digitalcollections.library.oregonstate.edu/cgi-bin/oai.exe', :parser =>'libxml'

last_check = Date.new(2006,8,1)
records = client.list_records :set => 'archives', :metadata_prefix => 'oai_dc', :from => last_check

records.each do |record|
  #fields = record.serialize_metadata(record.metadata, "oai_dc", "Oai_Dc")
  #puts "Primary Title: " + fields.title[0] + "\n"
  puts record.header.identifier + "\n"

end

puts 'finished'

