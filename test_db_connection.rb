require 'pg'

begin
  # Intentar conectar a la base de datos
  conn = PG.connect(
    host: 'localhost',
    port: 5432,
    dbname: 'postgres',
    user: 'postgres',
    password: 'postgres'
  )
  
  puts "¡Conexión exitosa a PostgreSQL!"
  puts "Versión del servidor: #{conn.server_version}"
  
  # Verificar si la base de datos auth_db existe
  result = conn.exec("SELECT 1 FROM pg_database WHERE datname = 'auth_db'")
  if result.ntuples > 0
    puts "La base de datos 'auth_db' existe."
  else
    puts "La base de datos 'auth_db' no existe. Creándola..."
    conn.exec("CREATE DATABASE auth_db")
    puts "Base de datos 'auth_db' creada exitosamente."
  end
  
  # Cerrar la conexión
  conn.close
  
rescue PG::Error => e
  puts "Error al conectar a PostgreSQL: #{e.message}"
end
