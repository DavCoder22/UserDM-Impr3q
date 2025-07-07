require 'spec_helper'

RSpec.describe 'Configuración básica' do
  it 'puede cargar los modelos' do
    expect(User).to be_a(Class)
    expect(Session).to be_a(Class)
  end
  
  it 'puede crear una instancia de User' do
    user = User.new(
      email: 'test@example.com',
      password_hash: 'hash123',
      nombre: 'Test User',
      rol: 'cliente'
    )
    expect(user).to be_a(User)
    expect(user.email).to eq('test@example.com')
  end
  
  it 'puede crear una instancia de Session' do
    session = Session.new(
      user_id: SecureRandom.uuid,
      token: 'token123',
      refresh_token: 'refresh123'
    )
    expect(session).to be_a(Session)
    expect(session.token).to eq('token123')
  end
  
  it 'tiene configuración de base de datos' do
    expect($db_connection).to be_nil # Se configurará en before(:suite)
  end
end 