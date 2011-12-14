```            _                             _ 
 _ __ _   _| |__  _   _        ___   __ _(_)
| '__| | | | '_ \| | | |_____ / _ \ / _` | |
| |  | |_| | |_) | |_| |_____| (_) | (_| | |
|_|   \__,_|_.__/ \__, |      \___/ \__,_|_|
                  |___/                     
```

ruby-oai is a Open Archives Protocol for Metadata Harvesting (OAI-PMH)
library for Ruby. OAI-PMH[http://openarchives.org] it is a somewhat 
archaic protocol for sharing metadata between digital library repositories. 
If you are looking to share metadata on the web you are probably better off
using a feed format like RSS or Atom. If have to work with a backwards 
digital repository that only offers OAI-PMH access then ruby-oai is your 
friend.

The [OAI-PMH](http://openarchives.org) spec defines six verbs (Identify, ListIdentifiers, ListRecords, 
GetRecords, ListSets, ListMetadataFormat) used for discovery and sharing of
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
  for record in client.list_records
    puts record.metadata
  end
```

See OAI::Client for more details

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

See OAI::Provider for more details

Interactive Harvester
---------------------

The OAI-PMH[http://openarchives.org] client shell allows OAI Harvesting to be configured in
an interactive manner.  Typing 'oai' on the command line starts the
shell.

After initial configuration, the shell can be used to manage harvesting
operations.

See OAI::Harvester::Shell for more details

Installation
------------

Normally the best way to install oai is from rubyforge using the gem
command line tool:

  % gem install oai

If you're reading this you've presumably got the tarball or zip distribution.
So you'll need to:

  % rake package
  % gem install pkg/oai-x.y.z.gem 

Where x.y.z is the version of the gem that was generated.

License
-------

[Public Domain](http://creativecommons.org/publicdomain/zero/1.0/)

Authors
-------

* Ed Summers <ehs@pobox.com>
* William Groppe <will.groppe@gmail.com>
* Terry Reese <terry.reese@oregonstate.edu>

