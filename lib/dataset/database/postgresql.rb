module Dataset
  module Database # :nodoc:
    
    # The interface to a PostgreSQL database, this will capture by creating a dump
    # file and restore by loading one of the same.
    #
    class Postgresql < Base
      def initialize(database_spec, storage_path)
        @database = database_spec[:database]
        @username = database_spec[:username]
        @password = database_spec[:password]
        @storage_path = storage_path
        FileUtils.mkdir_p(@storage_path)
      end
    end
  end
end