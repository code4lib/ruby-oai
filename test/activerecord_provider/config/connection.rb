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

ActiveRecord::MigrationContext.new(File.join(File.dirname(__FILE__), '..', 'database')).migrate


