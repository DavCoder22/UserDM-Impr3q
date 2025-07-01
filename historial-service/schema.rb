# Esquema GraphQL básico para el servicio de historial
class Types::QueryType < GraphQL::Schema::Object
  field :events, [Types::EventType], null: false
  field :event, Types::EventType, null: true do
    argument :id, ID, required: true
  end

  def events
    DB[:events].all
  end

  def event(id:)
    DB[:events].where(id: id).first
  end
end

class Types::EventType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :email, String, null: false
  field :event_type, String, null: false
  field :payload, GraphQL::Types::JSON, null: true
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
end

class Schema < GraphQL::Schema
  query Types::QueryType
end
