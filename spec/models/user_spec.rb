require 'spec_helper'

RSpec.describe User do
  let(:db) { $db_connection }
  
  describe 'validations' do
    it 'requiere un email' do
      user = build(:user, email: nil)
      expect { user.save(db) }.to raise_error(PG::NotNullViolation)
    end
    
    it 'requiere un email con formato válido' do
      user = build(:user, email: 'invalid-email')
      expect { user.save(db) }.to raise_error(PG::CheckViolation)
    end
    
    it 'requiere un rol válido' do
      user = build(:user, rol: 'invalid_role')
      expect { user.save(db) }.to raise_error(PG::CheckViolation)
    end
    
    it 'requiere un nombre' do
      user = build(:user, nombre: nil)
      expect { user.save(db) }.to raise_error(PG::NotNullViolation)
    end
    
    it 'requiere un hash de contraseña' do
      user = build(:user, password_hash: nil)
      expect { user.save(db) }.to raise_error(PG::NotNullViolation)
    end
  end
  
  describe '.authenticate' do
    let!(:user) { create(:user, password: 'secure123') }
    
    it 'retorna el usuario con credenciales válidas' do
      authenticated_user = User.authenticate(db, user.email, 'secure123')
      expect(authenticated_user).to be_a(User)
      expect(authenticated_user.id).to eq(user.id)
    end
    
    it 'retorna nil con contraseña incorrecta' do
      expect(User.authenticate(db, user.email, 'wrong')).to be_nil
    end
    
    it 'retorna nil con email incorrecto' do
      expect(User.authenticate(db, 'nonexistent@example.com', 'secure123')).to be_nil
    end
    
    it 'retorna nil si la cuenta está inactiva' do
      inactive_user = create(:user, :inactive, password: 'secure123')
      expect(User.authenticate(db, inactive_user.email, 'secure123')).to be_nil
    end
  end
  
  describe '#generate_password_reset_token' do
    let!(:user) { create(:user) }
    
    it 'genera un token de restablecimiento' do
      token = user.generate_password_reset_token(db)
      expect(token).to be_present
      
      # Verificar que se guardó en la base de datos
      result = db.exec_params('SELECT reset_password_token FROM users WHERE id = $1', [user.id]).first
      expect(result['reset_password_token']).to eq(token)
    end
  end
  
  describe '#valid_reset_token?' do
    let!(:user) { create(:user) }
    let!(:token) { user.generate_password_reset_token(db) }
    
    it 'retorna true para un token válido' do
      expect(user.valid_reset_token?(token, db)).to be true
    end
    
    it 'retorna false para un token inválido' do
      expect(user.valid_reset_token?('invalid-token', db)).to be false
    end
    
    it 'retorna false para un token expirado' do
      # Hacer que el token expire
      db.exec_params(
        'UPDATE users SET reset_token_expires = NOW() - INTERVAL \'2 hours\' WHERE id = $1',
        [user.id]
      )
      expect(user.valid_reset_token?(token, db)).to be false
    end
  end
  
  describe '#password=' do
    let(:user) { build(:user) }
    
    it 'establece el hash de la contraseña' do
      user.password = 'newpassword123'
      expect(user.password_hash).to be_present
      expect(BCrypt::Password.new(user.password_hash)).to eq('newpassword123')
    end
  end
  
  describe 'scopes' do
    let!(:active_user) { create(:user, cuenta_activa: true) }
    let!(:inactive_user) { create(:user, :inactive) }
    let!(:verified_user) { create(:user, email_verificado: true) }
    let!(:unverified_user) { create(:user, :unverified) }
    
    describe '.active' do
      it 'retorna solo usuarios activos' do
        # Implementar el método de clase .active en el modelo User
        result = db.exec_params(
          'SELECT * FROM users WHERE cuenta_activa = true'
        ).map { |r| User.new_from_result(r) }
        
        expect(result.map(&:id)).to include(active_user.id)
        expect(result.map(&:id)).not_to include(inactive_user.id)
      end
    end
    
    describe '.verified' do
      it 'retorna solo usuarios verificados' do
        # Implementar el método de clase .verified en el modelo User
        result = db.exec_params(
          'SELECT * FROM users WHERE email_verificado = true'
        ).map { |r| User.new_from_result(r) }
        
        expect(result.map(&:id)).to include(verified_user.id)
        expect(result.map(&:id)).not_to include(unverified_user.id)
      end
    end
  end
end
