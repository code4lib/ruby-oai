require 'models'

class SimpleProvider < OAI::Provider
  name 'Test Provider'
  prefix 'oai:test'
  model SimpleModel.new
end

class BigProvider < OAI::Provider
  name 'Another Provider'
  prefix 'oai:test'
  model BigModel.new
end

class TokenProvider < OAI::Provider
  name 'Token Provider'
  prefix 'oai:test'
  model BigModel.new(25)
end

class MappedProvider < OAI::Provider
  name 'Mapped Provider'
  prefix 'oai:test'
  model MappedModel.new
end

class ComplexProvider < OAI::Provider
  name 'Complex Provider'
  prefix 'oai:test'
  url 'http://localhost'
  model ComplexModel.new(100)
end

