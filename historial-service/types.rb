module Types
  class BaseObject < GraphQL::Schema::Object
  end

  class EventType < BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :event_type, String, null: false
    field :payload, GraphQL::Types::JSON, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end

  class QueryType < BaseObject
    field :events, [EventType], null: false
    field :event, EventType, null: true do
      argument :id, ID, required: true
    end

    def events
      DB[:events].all
    end

    def event(id:)
      DB[:events].where(id: id).first
    end
  end
end
