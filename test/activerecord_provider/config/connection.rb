require 'active_record'
require 'logger'

# Configure AR connection
#ActiveRecord::Base.logger = Logger.new(STDOUT)

if RUBY_PLATFORM == "java"
  require 'jdbc/sqlite3'
  Jdbc::SQLite3.load_driver
end

ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection :adapter => "sqlite3",
                                        :database => ":memory:"

if ActiveRecord.version < Gem::Version.new("6.0.0")
  ActiveRecord::MigrationContext.new(
    File.join(File.dirname(__FILE__), '..', 'database')
  ).migrate
else
  ActiveRecord::MigrationContext.new(
    File.join(File.dirname(__FILE__), '..', 'database'),
    ActiveRecord::Base.connection.schema_migration
  ).migrate
end

