source "http://rubygems.org"

gemspec

gem 'jruby-openssl', :platform => :jruby

group :test do
  gem 'activerecord', '~> 3.2.8'
  gem 'activerecord-jdbcsqlite3-adapter', :platform => [:jruby]
  gem 'libxml-ruby', :platform => [:ruby, :mswin]
  gem 'rake'
  gem 'yard'
  gem 'redcarpet', :platform => :ruby # For fast, Github-like Markdown
  gem 'kramdown', :platform => :jruby # For Markdown without a C compiler
  gem 'rcov', '~> 0.9', :platform => [:ruby_18, :jruby]
  gem 'simplecov', :platform => :ruby_19
  gem 'simplecov-rcov', :platform => :ruby_19
  gem 'sqlite3', :platform => [:ruby, :mswin]
end
