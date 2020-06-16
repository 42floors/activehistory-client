module ActiveHistory::Adapter
  module Wal
    extend ActiveSupport::Concern

    class_methods do

      def self.extended(klass)
        if ActiveHistory.configured?
          other.before_commit :update_activehistory_metadata
        end
      end

      private

      def update_activehistory_metadata
        event = Thread.current[:activehistory_event]

        return if !event

        binds = [
          ActiveRecord::Relation::QueryAttribute.new("data",
            { metadata: event.metadata.as_json, event_id: event.id },
            ActiveRecord::Type.lookup(:jsonb, adapter: :postgresql)
          )]
        ActiveRecord::Base.connection.exec_query(<<-SQL, 'SQL', binds, prepare: true)
          INSERT INTO ah_metadata (version, data)
          VALUES (1, $1)
          ON CONFLICT (version) DO UPDATE SET version = 1, data = $1;
        SQL
      end

    end

    end

  end
end
