require 'pg'

begin
  # Configuración de conexión
  conn = PG.connect(
    host: 'localhost',
    port: 5435,
    dbname: 'auth_db_test',
    user: 'postgres',
    password: 'postgres'
  )
  
  puts "¡Conexión exitosa a la base de datos!"
  
  # Ejecutar una consulta de prueba
  result = conn.exec("SELECT 1 AS test")
  puts "Resultado de la consulta: #{result[0]['test']}"
  
  # Verificar si la tabla users existe
  begin
    users_count = conn.exec("SELECT COUNT(*) FROM users")[0]['count']
    puts "La tabla 'users' existe y tiene #{users_count} registros."
  rescue PG::UndefinedTable
    puts "La tabla 'users' no existe."
  end
  
  conn.close
  
rescue PG::Error => e
  puts "Error al conectar a la base de datos: #{e.message}
"
  puts "Detalles del error:"
  puts "- Mensaje: #{e.message}"
  puts "- Backtrace: #{e.backtrace.join("\n")}"
  
  # Intentar obtener más información sobre el error de autenticación
  if e.message.include?("password authentication failed")
    puts "\nPosible error de autenticación. Verifica las credenciales de la base de datos."
  end
  
  # Mostrar información de conexión utilizada
  puts "\nParámetros de conexión utilizados:"
  puts "- Host: localhost"
  puts "- Puerto: 5435"
  puts "- Base de datos: auth_db_test"
  puts "- Usuario: postgres"
  puts "- Contraseña: [protegida]"
  
  # Sugerencia para verificar los contenedores en ejecución
  puts "\nSugerencia: Verifica que el contenedor de PostgreSQL esté en ejecución con 'docker ps'"
  
  exit 1
end
