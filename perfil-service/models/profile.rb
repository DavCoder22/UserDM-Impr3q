require 'securerandom'
require 'bcrypt'

class Profile < Sequel::Model
  # Configuración de la tabla
  set_primary_key :id
  
  # Asociaciones
  many_to_one :user, key: :user_id, class: :User
  
  # Validaciones
  def validate
    super
    validates_presence [:user_id, :nombre_completo, :correo]
    validates_unique :user_id
    validates_format /^[^@\s]+@[^@\s]+\.[^@\s]+$/, :correo, message: 'no es un correo válido'
  end
  
  # Callbacks
  def before_validation
    self.correo = correo.downcase if correo
    super
  end
  
  # Métodos de instancia
  
  # Actualiza los datos del perfil
  def update_profile(attrs)
    set(attrs)
    save_changes
  end
  
  # Serializa el perfil a un hash
  def to_api
    {
      id: id,
      user_id: user_id,
      nombre_completo: nombre_completo,
      correo: correo,
      telefono: telefono,
      direccion: direccion,
      fecha_nacimiento: fecha_nacimiento&.iso8601,
      genero: genero,
      avatar_url: avatar_url,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601
    }
  end
  
  # Métodos de clase
  
  # Busca un perfil por ID de usuario
  def self.find_by_user_id(user_id)
    first(user_id: user_id)
  end
  
  # Busca un perfil por correo electrónico
  def self.find_by_email(email)
    first(correo: email.downcase)
  end
  
  # Crea un nuevo perfil para un usuario
  def self.create_for_user(user_id, profile_attrs)
    create(profile_attrs.merge(user_id: user_id))
  end
  
  # Actualiza el avatar de un perfil
  def self.update_avatar(user_id, avatar_url)
    profile = find(user_id: user_id)
    return nil unless profile
    
    old_avatar = profile.avatar_url
    profile.update(avatar_url: avatar_url)
    
    # Aquí podrías agregar lógica para eliminar el avatar anterior si es necesario
    # File.delete(old_avatar) if old_avatar && File.exist?(old_avatar)
    
    profile
  end
  
  # Métodos para búsqueda avanzada
  def self.search(query)
    where(Sequel.lit("nombre_completo ILIKE ? OR correo ILIKE ?", 
                     "%#{query}%", "%#{query}%"))
  end
  
  # Métodos para estadísticas
  def self.count_by_gender
    group_and_count(:genero).all
  end
  
  def self.average_age
    return nil unless DB.database_type == :postgres
    
    # Solo funciona con PostgreSQL
    DB["SELECT AVG(EXTRACT(YEAR FROM age(fecha_nacimiento))) AS avg_age FROM profiles"].first[:avg_age]&.to_f
  end
end
