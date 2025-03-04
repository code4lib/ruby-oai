Gem::Specification.new do |s|
    s.name = 'oai'
    s.version = '1.3.0'
    s.author = 'Ed Summers'
    s.email = 'ehs@pobox.com'
    s.homepage = 'http://github.com/code4lib/ruby-oai'
    s.platform = Gem::Platform::RUBY
    s.summary = 'A ruby library for working with the Open Archive Initiative Protocol for Metadata Harvesting (OAI-PMH)'
    s.license = 'MIT'
    s.require_path = 'lib'
    s.autorequire = 'oai'
    s.bindir = 'bin'
    s.executables = 'oai'

    s.add_dependency('builder', '>=3.1.0')
    s.add_dependency('faraday', "< 3")
    s.add_dependency("faraday-follow_redirects", ">= 0.3.0", "< 2")
    s.add_dependency("rexml") # rexml becomes bundled gem in ruby 3.0


    s.add_development_dependency "activerecord", ">= 5.2.0", "< 8.1"
    s.add_development_dependency "appraisal"
    s.add_development_dependency "webrick"


    s.files = %w(README.md Rakefile) +
      Dir.glob("{bin,test,lib}/**/*") +
      Dir.glob("examples/**/*.rb")
end
