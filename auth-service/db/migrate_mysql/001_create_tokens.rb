Sequel.migration do
  change do
    create_table(:tokens) do
      primary_key :id, type: :Bignum
      Bignum :usuario_id, null: false
      String :jwt, null: false, text: true
      DateTime :creado_en, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :expira_en, null: false
      
      index :jwt, unique: true
      index :usuario_id
      index :expira_en
    end
  end
end
