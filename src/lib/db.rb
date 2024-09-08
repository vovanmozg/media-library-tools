require 'sqlite3'
require 'sequel'

def db_path
  defined?(TEST_ENV) && TEST_ENV ? './tmp/files_info.db' : '/vt/data/files_info.db'
end

# DB = SQLite3::Database.new(DB_PATH)
# DB.results_as_hash = true

DB = Sequel.connect("sqlite://#{db_path}")
unless DB.table_exists?(:cache)
  DB.create_table :cache do
    String :key, null: false, size: 32, unique: true, primary_key: true
    String :id
    Integer :mtime
    Integer :size
    String :name, null: false
    String :phash
    String :md5, size: 32
    String :type, size: 5
    Integer :width
    Integer :height
    Text :additional_data
  end
end

class ModelCache < Sequel::Model(:cache)
  unrestrict_primary_key
end
