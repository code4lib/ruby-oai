ruby-oai
========

ruby-oai is a Open Archives Protocol for Metadata Harvesting (OAI-PMH)
library for Ruby. [OAI-PMH](http://openarchives.org) is a somewhat 
archaic protocol for sharing metadata between digital library repositories. 
If you are looking to share metadata on the web you are probably better off
using a feed format like [RSS](http://www.rssboard.org/rss-specification) or 
[Atom](http://www.atomenabled.org/). If have to work with a backwards 
digital repository that only offers OAI-PMH access then ruby-oai is your 
friend.

The [OAI-PMH](http://openarchives.org) spec defines six verbs 
(`Identify`, `ListIdentifiers`, `ListRecords`, 
`GetRecords`, `ListSets`, `ListMetadataFormat`) used for discovery and sharing of
metadata.

The ruby-oai gem includes a client library, a server/provider library and
a interactive harvesting shell.

Client
------

The OAI client library is used for harvesting metadata from repositories. 
For example to initiate a ListRecords request to pubmed you can:

```ruby
  require 'oai'
  client = OAI::Client.new 'http://www.pubmedcentral.gov/oai/oai.cgi'
  response = client.list_records
  # Get the first page of records
  response.each do |record| 
    puts record.metadata
  end
  # Get the second page of records
  response = client.list_records(:resumption_token => response.resumption_token)
  response.each do |record|
    puts record.metadata
  end
  # Get all pages together (may take a *very* long time to complete)
  client.list_records.full.each do |record|
    puts record.metadata
  end
```

See {OAI::Client} for more details

Server
------

The OAI provider library handles serving local content to other clients. Here's how to set up a simple provider:

```ruby
  class MyProvider < Oai::Provider
    repository_name 'My little OAI provider'
    repository_url  'http://localhost/provider'
    record_prefix 'oai:localhost'
    admin_email 'root@localhost'   # String or Array
    source_model MyModel.new       # Subclass of OAI::Provider::Model
  end
```

See {OAI::Provider} for more details

Interactive Harvester
---------------------

The OAI-PMH client shell allows OAI Harvesting to be configured in an interactive manner.  Typing `oai` on the command line starts the shell. After initial configuration, the shell can be used to manage harvesting operations.

See {OAI::Harvester::Shell} for more details

Installation
------------

Normally the best way to install oai is as part of your `Gemfile`:

    source :rubygems
    gem 'oai'

Alternately it can be installed globally using RubyGems:

    $ gem install oai

License
-------

[![CC0 - Public Domain](http://i.creativecommons.org/p/zero/1.0/88x15.png)](http://creativecommons.org/publicdomain/zero/1.0/)
