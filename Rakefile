
require 'rubygems'
require 'rake'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

require 'rake/testtask'
require 'rake/rdoctask'

task :default => ["test"]

task :test => ["test:client", "test:provider"]

namespace :test do
  Rake::TestTask.new('client') do |t|
    t.libs << ['lib', 'test/client']
    t.pattern = 'test/client/tc_*.rb'
    t.verbose = true
  end

  Rake::TestTask.new('provider') do |t|
    t.libs << ['lib', 'test/provider']
    t.pattern = 'test/provider/tc_*.rb'
    t.verbose = true
  end

  desc "Active Record base Provider Tests"
  Rake::TestTask.new('activerecord_provider') do |t|
    t.libs << ['lib', 'test/activerecord_provider']
    t.pattern = 'test/activerecord_provider/tc_*.rb'
    t.verbose = true
  end

  desc 'Measures test coverage'
  # borrowed from here: http://clarkware.com/cgi/blosxom/2007/01/05#RcovRakeTask
  task :coverage do
    rm_f "coverage"
    rm_f "coverage.data"
    if RUBY_VERSION =~ /^1.8/
      Rake::Task['rcov:client'].invoke
      Rake::Task['rcov:provider'].invoke
    else
      ENV['COVERAGE'] = 'true'
      Rake::Task['test:client'].invoke
      Rake::Task['test:provider'].invoke
    end

    system("open coverage/index.html") if (PLATFORM['darwin'] if Kernel.const_defined? :PLATFORM) || (RUBY_PLATFORM =~ /darwin/ if Kernel.const_defined? :RUBY_PLATFORM)
  end

end

if RUBY_VERSION =~ /^1.8/
  require 'rcov/rcovtask'
  namespace :rcov do
    Rcov::RcovTask.new do |t|
      t.name = 'client'
      t.libs << ['lib', 'test/client']
      t.pattern = 'test/client/tc_*.rb'
      t.verbose = true
      t.rcov_opts = ['--aggregate coverage.data', '--text-summary']
    end

    Rcov::RcovTask.new('provider') do |t|
      t.libs << ['lib', 'test/provider']
      t.pattern = 'test/provider/tc_*.rb'
      t.verbose = true
      t.rcov_opts = ['--aggregate coverage.data', '--text-summary']
    end
  end
end

task 'test:activerecord_provider' => :create_database

task :environment do 
  unless defined? OAI_PATH
    OAI_PATH = File.dirname(__FILE__) + '/lib/oai'
    $LOAD_PATH << OAI_PATH
    $LOAD_PATH << File.dirname(__FILE__) + '/test'
  end
end

task :drop_database => :environment do
  %w{rubygems active_record yaml}.each { |lib| require lib }
  require 'activerecord_provider/database/ar_migration'
  require 'activerecord_provider/config/connection'
  begin
    OAIPMHTables.down
  rescue
  end
end

task :create_database => :drop_database do
  OAIPMHTables.up
end

task :load_fixtures => :create_database do
  require 'test/activerecord_provider/models/dc_field'
  fixtures = YAML.load_file(
    File.join('test', 'activerecord_provider', 'fixtures', 'dc.yml')
  )
  fixtures.keys.sort.each do |key|
    DCField.create(fixtures[key])
  end
end
  
Rake::RDocTask.new('doc') do |rd|
  rd.rdoc_files.include("lib/**/*.rb", "README.md")
  rd.main = 'README.md'
  rd.rdoc_dir = 'doc'
end
