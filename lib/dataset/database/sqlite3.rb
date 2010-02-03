module Dataset
  module Database # :nodoc:
    
    # The interface to a sqlite3 database, this will capture by copying the db
    # file and restore by replacing and reconnecting to one of the same.
    #
    class Sqlite3 < Base
      def initialize(database_spec, storage_path)
        @database_path, @storage_path = database_spec[:database], storage_path
        FileUtils.mkdir_p(@storage_path)
      end
    end
  end
end