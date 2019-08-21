source "http://rubygems.org"

gemspec

gem 'jruby-openssl', :platform => :jruby

group :test do
  gem 'activerecord', '~> 5.0.0'
  gem 'activerecord-jdbcsqlite3-adapter', :platform => [:jruby]
  gem 'libxml-ruby', :platform => [:ruby, :mswin]
  gem 'rake'
  gem 'yard'
  gem 'redcarpet', :platform => :ruby # For fast, Github-like Markdown
  gem 'kramdown', :platform => :jruby # For Markdown without a C compiler
  gem 'test-unit'
  # This version of sqlite3 required for activerecord 5.0, not more recent.
  # When bumping AR, may have to/want to adjust this to more recent versions.
  gem 'sqlite3', "~> 1.3.6", :platform => [:ruby, :mswin]
end
