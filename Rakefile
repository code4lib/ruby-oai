
require 'rubygems'
require 'rake'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

require 'rake/testtask'
require 'yard'

task :default => ["test", "yard"]

Rake::TestTask.new('test') do |t|
  t.description = "Run all Test::Unit tests"

  t.libs << ['lib', 'test/client', 'test/provider', 'test/activerecord_provider']

  t.pattern = 'test/{client,provider,activerecord_provider}/tc_*.rb'
  #t.verbose = true
  t.warning = false
end


# To run just subsets of tests
namespace :test do
  Rake::TestTask.new('client') do |t|
    t.libs << ['lib', 'test/client']
    t.pattern = 'test/client/tc_*.rb'
    #t.verbose = true
    t.warning = false
  end

  Rake::TestTask.new('harvester') do |t|
    t.libs << ['lib', 'test/harvester']
    t.pattern = 'test/harvester/tc_*.rb'
    #t.verbose = true
    t.warning = false
  end

  Rake::TestTask.new('provider') do |t|
    t.libs << ['lib', 'test/provider']
    t.pattern = 'test/provider/tc_*.rb'
    #t.verbose = true
    t.warning = false
  end

  Rake::TestTask.new('activerecord_provider') do |t|
    t.description = "Active Record base Provider Tests"

    t.libs << ['lib', 'test/activerecord_provider']
    t.pattern = 'test/activerecord_provider/tc_*.rb'
    #t.verbose = true
    t.warning = false
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]
  t.options = ['--output-dir', 'doc']
end
