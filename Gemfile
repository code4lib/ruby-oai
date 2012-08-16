source "http://rubygems.org"

gemspec

gem 'jruby-openssl', :platform => :jruby

group :test do
  gem 'activerecord'
  gem 'activerecord-jdbcsqlite3-adapter', :platform => [:jruby]
  gem 'libxml-ruby', :platform => [:ruby, :mswin]
  gem 'rake'
  gem 'rdoc'
  gem 'rcov', '~> 0.9', :platform => [:ruby_18, :jruby]
  gem 'simplecov', :platform => :ruby_19
  gem 'simplecov-rcov', :platform => :ruby_19
  gem 'sqlite3', :platform => [:ruby, :mswin]
end
