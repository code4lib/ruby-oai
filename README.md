ruby-oai
========
[![Build Status](https://github.com/code4lib/ruby-oai/workflows/CI/badge.svg)](https://github.com/code4lib/ruby-oai/actions)

[![Gem Version](https://badge.fury.io/rb/kithe.svg)](https://badge.fury.io/rb/oai)

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
  client = OAI::Client.new 'http://www.pubmedcentral.gov/oai/oai.cgi', :headers => { "From" => "oai@example.com" }
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

### Retry-After
This library depends on faraday, but allows a wide range of versions. Depending on the client application's installed version of faraday, there may be different middleware libraries required to support automatically retrying requests that are rate limited/denied with a `Retry-After` header. The OAI client can, however, accept an externally configured faraday http client for handling this. For example, to retry on `429 Too Many Requests`:

```ruby
require 'oai'
require 'faraday_middleware' # if using faraday version < 2
http_client = Faraday.new do |conn|
    conn.request(:retry, max: 5, retry_statuses: 429)
    conn.response(:follow_redirects, limit: 5)
    conn.adapter :net_http
end
client = OAI::Client.new(base_url, http: http_client)
opts = {from:'2012-03-01', until:'2012-04-01', metadata_prefix:'oai_dc'}
puts client.list_records(opts).full.count
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

See comment docs at top of [OAI::Provider](./lib/oai/provider.rb) for more details, including discussion of the `OAI::Provider::ActiveRecordWrapper` class for quich setup of an OAI provider for an ActiveRecord model class (single database table)

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

Running tests
-------------

Tests are with Test::Unit, in a somewhat archaic/legacy style. Test setup especially is not how we would do things today. Run all tests with:

    $ bundle exec rake test

There are also convenience tasks to run subsets of tests.

We use [appraisal](https://github.com/thoughtbot/appraisal) to test ActiveRecord-related functionality under multiple versions of ActiveRecord. While the above commands will test with latest ActiveRecord (allowed in our .gemspec development dependency), you can test under a particular version defined in the [Appraisals](./Appraisals) file like so:

    $ bundle exec appraisal rails-52 rake test
    $ bundle exec appraisal rails-70 rake test

If you run into trouble with appraisal's gemfiles getting out of date and bundler complaining,
try:

   $ bundle exec appraisal clean
   $ appraisal generate

That may make changes to appraisal gemfiles that you should commit to repo.

License
-------

[![CC0 - Public Domain](http://i.creativecommons.org/p/zero/1.0/88x15.png)](http://creativecommons.org/publicdomain/zero/1.0/)
