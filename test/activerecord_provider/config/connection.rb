require 'active_record'
require 'logger'

# Configure AR connection
#ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection :adapter => "sqlite3",
                                        :database => ":memory:"
ActiveRecord::Migrator.up File.join(File.dirname(__FILE__), '..', 'database')