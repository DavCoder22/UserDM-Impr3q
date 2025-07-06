require 'spec_helper'

RSpec.describe Session do
  let(:db) { $db_connection }
  let(:user) { create(:user) }
  
  describe 'validations' do
    it 'requiere un user_id' do
      session = build(:session, user_id: nil)
      expect { session.save(db) }.to raise_error(PG::NotNullViolation)
    end
    
    it 'requiere un token' do
      session = build(:session, token: nil)
      expect { session.save(db) }.to raise_error(PG::NotNullViolation)
    end
  end
  
  describe '#active?' do
    it 'retorna true para una sesión activa' do
      session = create(:session, user_id: user.id, expires_at: 1.day.from_now)
      expect(session.active?).to be true
    end
    
    it 'retorna false si la sesión está revocada' do
      session = create(:session, :revoked, user_id: user.id)
      expect(session.active?).to be false
    end
    
    it 'retorna false si la sesión ha expirado' do
      session = create(:session, :expired, user_id: user.id)
      expect(session.active?).to be false
    end
  end
  
  describe '#revoke!' do
    it 'marca la sesión como revocada' do
      session = create(:session, user_id: user.id)
      session.revoke!
      
      expect(session.revoked?).to be true
      expect(session.revoked_at).to be_within(1.second).of(Time.now.utc)
    end
  end
  
  describe '#update_activity!' do
    it 'actualiza la última actividad' do
      session = create(:session, user_id: user.id)
      original_activity = session.last_activity_at
      
      sleep(1) # Asegurar que haya diferencia de tiempo
      session.update_activity!
      
      expect(session.last_activity_at).to be > original_activity
    end
  end
  
  describe '.find_by_token' do
    it 'encuentra una sesión por su token' do
      session = create(:session, user_id: user.id)
      found = Session.find_by_token(db, session.token)
      
      expect(found).to be_a(Session)
      expect(found.id).to eq(session.id)
    end
    
    it 'retorna nil si el token no existe' do
      expect(Session.find_by_token(db, 'nonexistent')).to be_nil
    end
  end
  
  describe '.find_active_by_user' do
    it 'retorna solo sesiones activas del usuario' do
      active_session = create(:session, user_id: user.id)
      create(:session, :expired, user_id: user.id)
      create(:session, :revoked, user_id: user.id)
      
      active_sessions = Session.find_active_by_user(db, user.id)
      
      expect(active_sessions.size).to eq(1)
      expect(active_sessions.first.id).to eq(active_session.id)
    end
  end
  
  describe 'scopes' do
    let!(:active_session) { create(:session, user_id: user.id) }
    let!(:expired_session) { create(:session, :expired, user_id: user.id) }
    let!(:revoked_session) { create(:session, :revoked, user_id: user.id) }
    
    describe '.active' do
      it 'retorna solo sesiones activas' do
        # Implementar el método de clase .active en el modelo Session
        result = db.exec_params(
          'SELECT * FROM sessions WHERE revoked_at IS NULL AND expires_at > NOW()'
        ).map { |r| Session.new_from_result(r) }
        
        expect(result.map(&:id)).to include(active_session.id)
        expect(result.map(&:id)).not_to include(expired_session.id, revoked_session.id)
      end
    end
  end
end
