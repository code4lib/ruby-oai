Gem::Specification.new do |s|
    s.name = 'oai'
    s.version = '0.3.1'
    s.author = 'Ed Summers'
    s.email = 'ehs@pobox.com'
    s.homepage = 'http://github.com/code4lib/ruby-oai'
    s.platform = Gem::Platform::RUBY
    s.summary = 'A ruby library for working with the Open Archive Initiative Protocol for Metadata Harvesting (OAI-PMH)'
    s.require_path = 'lib'
    s.autorequire = 'oai'
    s.bindir = 'bin'
    s.executables = 'oai'

    s.add_dependency('builder', '>=2.0.0')
    s.add_dependency('faraday')
    s.add_dependency('faraday_middleware')

    s.files = %w(README.md Rakefile) +
      Dir.glob("{bin,test,lib}/**/*") +
      Dir.glob("examples/**/*.rb")
end
