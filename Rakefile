
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

task :test => ["test:client", "test:provider", "test:activerecord_provider"]

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
      Rake::Task['rcov:activerecord_provider'].invoke
    else
      ENV['COVERAGE'] = 'true'
      Rake::Task['test:client'].invoke
      Rake::Task['test:provider'].invoke
      Rake::Task['test:activerecord_provider'].invoke
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

    Rcov::RcovTask.new('activerecord_provider') do |t|
      t.libs << ['lib', 'test/activerecord_provider']
      t.pattern = 'test/activerecord_provider/tc_*.rb'
      t.verbose = true
      t.rcov_opts = ['--aggregate coverage.data', '--text-summary']
    end
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]
  t.options = ['--output-dir', 'doc']
end
