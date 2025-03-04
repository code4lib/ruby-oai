source "http://rubygems.org"

gemspec

gem 'jruby-openssl', :platform => :jruby

group :test do
  gem 'activerecord-jdbcsqlite3-adapter', :platform => [:jruby]
  gem 'libxml-ruby', :platform => [:ruby, :mswin]
  gem 'rake'
  gem 'yard'
  gem 'redcarpet', :platform => :ruby # For fast, Github-like Markdown
  gem 'kramdown', :platform => :jruby # For Markdown without a C compiler
  gem 'test-unit'

  # This version of sqlite3 oughta be good for activerecord 5.1+ hopefully
  gem 'sqlite3', ">= 1.4.0", "< 3.0", :platform => [:ruby, :mswin]
end
