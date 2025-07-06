puts "¡Hola desde Ruby!"
begin
  require 'pg'
  puts "La gema 'pg' se cargó correctamente."
  
  # Mostrar información de la versión de la gema pg
  puts "Versión de la gema pg: #{PG.library_version}"
  
  # Intentar conectar a la base de datos
  conn = PG.connect(
    host: 'db',
    port: 5432,
    dbname: 'auth_db_test',
    user: 'postgres',
    password: 'postgres'
  )
  
  puts "¡Conexión exitosa a la base de datos!"
  
  # Ejecutar una consulta simple
  result = conn.exec("SELECT 1 AS test")
  puts "Resultado de la consulta: #{result[0]['test']}"
  
  conn.close
  
rescue LoadError => e
  puts "Error al cargar la gema 'pg': #{e.message}"
  puts "Intenta instalarla con: gem install pg"
rescue PG::Error => e
  puts "Error de PostgreSQL: #{e.message}"
  puts "Detalles del error:"
  puts "- Mensaje: #{e.message}"
  puts "- Backtrace: #{e.backtrace.join("\n")}"
rescue StandardError => e
  puts "Error inesperado: #{e.class}: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.join("\n")
end
