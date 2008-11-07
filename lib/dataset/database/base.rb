require 'fileutils'

module Dataset
  module Database
    class Base
      include FileUtils
      
      def clear
        ActiveRecord::Base.silence do
          ActiveRecord::Base.send(:subclasses).each do |ar|
            ar.connection.delete "DELETE FROM #{ar.connection.quote_table_name(ar.table_name)}",
              "Dataset clear_data_from_database" rescue nil
          end
        end
      end
      
      def record_meta(record_class)
        record_metas[record_class] ||= Dataset::Record::Meta.new(record_class)
      end
      
      protected
        def record_metas
          @record_metas ||= Hash.new
        end
    end
  end
end