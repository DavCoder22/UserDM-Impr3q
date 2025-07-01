Sequel.migration do
  change do
    create_table(:usuarios) do
      primary_key :id, type: :Bignum
      String :nombre, null: false
      String :correo, null: false, unique: true
      String :password_hash, null: false
      String :rol, null: false, default: 'usuario'
      DateTime :fecha_creacion, null: false, default: Sequel::CURRENT_TIMESTAMP
      
      index :correo, unique: true
    end
  end
end
