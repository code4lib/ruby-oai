RUBY_OAI_VERSION = '0.0.3'

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'

task :default => [:test]

Rake::TestTask.new('test') do |t|
  t.libs << 'lib'
  t.pattern = 'test/tc_*.rb'
  t.verbose = true
  t.ruby_opts = ['-r oai', '-r test/unit']
end

spec = Gem::Specification.new do |s|
    s.name = 'oai'
    s.version = RUBY_OAI_VERSION
    s.author = 'Ed Summers'
    s.email = 'ehs@pobox.com'
    s.homepage = 'http://www.textualize.com/ruby-marc'
    s.platform = Gem::Platform::RUBY
    s.summary = 'A ruby library for working with the Open Archive Initiative Protocol for Metadata Harvesting (OAI-PMH)'
    s.files = Dir.glob("{lib,test}/**/*")
    s.require_path = 'lib'
    s.autorequire = 'oai'
    s.has_rdoc = true
    s.bindir = 'bin'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::RDocTask.new('doc') do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
  rd.main = 'OAI::Client'
  rd.rdoc_dir = 'doc'
end
