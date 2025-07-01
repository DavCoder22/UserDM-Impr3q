Sequel.migration do
  up do
    create_table(:profiles) do
      primary_key :id, type: :Bignum
      foreign_key :user_id, :users, type: :Bignum, null: false, index: true
      
      String :nombre_completo, null: false
      String :correo, null: false, index: true
      String :telefono
      String :direccion, text: true
      Date :fecha_nacimiento
      String :genero, size: 1  # M: Masculino, F: Femenino, O: Otro
      String :avatar_url
      
      # Campos de auditoría
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      
      # Índices
      index [:user_id], unique: true, name: 'unique_user_profile'
      index [:correo], unique: true, name: 'unique_profile_email'
    end
    
    # Agregar trigger para actualizar automáticamente el campo updated_at
    run <<-SQL
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      
      CREATE TRIGGER update_profiles_updated_at
      BEFORE UPDATE ON profiles
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    SQL
  end
  
  down do
    drop_trigger(:update_profiles_updated_at, :profiles)
    drop_function(:update_updated_at_column)
    drop_table(:profiles)
  end
end
