require 'rubygems'
spec = Gem::Specification.new do |s|
    s.name = 'oai'
    s.version = '0.0.1'
    s.author = 'Ed Summers'
    s.email = 'ehs@pobox.com'
    s.homepage = 'http://www.textualize.com/ruby-marc'
    s.platform = Gem::Platform::RUBY
    s.summary = 'A ruby library for working with the Open Archive Initiative Protocol for Metadata Harvesting (OAI-PMH)'
    s.files = Dir.glob("{lib,test}/**/*")
    s.require_path = 'lib'
    s.autorequire = 'oai'
    s.has_rdoc = true
    s.test_file = 'test.rb'
    s.bindir = 'bin'
end

if $0 == __FILE__
    Gem::manage_gems
    Gem::Builder.new(spec).build
end

