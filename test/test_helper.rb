require 'models'
require 'provider'

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
  paginator OAI::SimplePaginator.new(25)
  model BigModel.new
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
  paginator OAI::SimplePaginator.new(100)
  model ComplexModel.new
end

