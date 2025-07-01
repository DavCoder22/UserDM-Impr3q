require 'spec_helper'

RSpec.describe Profile do
  describe 'validations' do
    let(:profile) { build(:profile) }
    
    it 'es válido con atributos válidos' do
      expect(profile).to be_valid
    end
    
    it 'es inválido sin user_id' do
      profile.user_id = nil
      expect(profile).not_to be_valid
      expect(profile.errors[:user_id]).to include('no puede estar vacío')
    end
    
    it 'es inválido sin nombre_completo' do
      profile.nombre_completo = nil
      expect(profile).not_to be_valid
      expect(profile.errors[:nombre_completo]).to include('no puede estar vacío')
    end
    
    it 'es inválido sin correo' do
      profile.correo = nil
      expect(profile).not_to be_valid
      expect(profile.errors[:correo]).to include('no puede estar vacío')
    end
    
    it 'es inválido con correo inválido' do
      profile.correo = 'correo-invalido'
      expect(profile).not_to be_valid
      expect(profile.errors[:correo]).to include('no es un correo válido')
    end
    
    it 'es inválido con user_id duplicado' do
      existing_profile = create(:profile)
      profile.user_id = existing_profile.user_id
      expect(profile).not_to be_valid
      expect(profile.errors[:user_id]).to include('ya está en uso')
    end
    
    it 'es inválido con correo duplicado' do
      existing_profile = create(:profile)
      profile.correo = existing_profile.correo
      expect(profile).not_to be_valid
      expect(profile.errors[:correo]).to include('ya está en uso')
    end
  end
  
  describe 'métodos de instancia' do
    let(:profile) { create(:profile) }
    
    describe '#update_profile' do
      it 'actualiza los atributos del perfil' do
        new_attributes = {
          nombre_completo: 'Nuevo Nombre',
          correo: 'nuevo@correo.com',
          telefono: '1234567890',
          direccion: 'Nueva Dirección',
          fecha_nacimiento: '1990-01-01',
          genero: 'M'
        }
        
        expect {
          profile.update_profile(new_attributes)
        }.to change { profile.reload.nombre_completo }.to('Nuevo Nombre')
         .and change { profile.correo }.to('nuevo@correo.com')
         .and change { profile.telefono }.to('1234567890')
      end
    end
    
    describe '#to_api' do
      it 'devuelve un hash con los atributos del perfil' do
        profile = create(:profile, 
                        nombre_completo: 'Juan Pérez',
                        correo: 'juan@example.com',
                        genero: 'M')
        
        result = profile.to_api
        
        expect(result).to include(
          id: profile.id,
          user_id: profile.user_id,
          nombre_completo: 'Juan Pérez',
          correo: 'juan@example.com',
          genero: 'M'
        )
        expect(result).to have_key(:created_at)
        expect(result).to have_key(:updated_at)
      end
    end
  end
  
  describe 'métodos de clase' do
    describe '.find_by_user_id' do
      it 'encuentra un perfil por user_id' do
        profile = create(:profile)
        found = described_class.find_by_user_id(profile.user_id)
        expect(found).to eq(profile)
      end
      
      it 'devuelve nil si no encuentra el perfil' do
        expect(described_class.find_by_user_id(9999)).to be_nil
      end
    end
    
    describe '.find_by_email' do
      it 'encuentra un perfil por correo' do
        profile = create(:profile, correo: 'test@example.com')
        found = described_class.find_by_email('test@example.com')
        expect(found).to eq(profile)
      end
      
      it 'es insensible a mayúsculas/minúsculas' do
        profile = create(:profile, correo: 'test@example.com')
        found = described_class.find_by_email('TEST@example.com')
        expect(found).to eq(profile)
      end
      
      it 'devuelve nil si no encuentra el correo' do
        expect(described_class.find_by_email('noexiste@example.com')).to be_nil
      end
    end
    
    describe '.search' do
      before do
        create(:profile, nombre_completo: 'Juan Pérez', correo: 'juan@example.com')
        create(:profile, nombre_completo: 'María López', correo: 'maria@example.com')
        create(:profile, nombre_completo: 'Carlos Gómez', correo: 'carlos@example.com')
      end
      
      it 'encuentra perfiles que coincidan con el nombre' do
        results = described_class.search('Juan')
        expect(results.count).to eq(1)
        expect(results.first.nombre_completo).to eq('Juan Pérez')
      end
      
      it 'encuentra perfiles que coincidan con el correo' do
        results = described_class.search('maria@example.com')
        expect(results.count).to eq(1)
        expect(results.first.correo).to eq('maria@example.com')
      end
      
      it 'es insensible a mayúsculas/minúsculas' do
        results = described_class.search('jUaN')
        expect(results.count).to eq(1)
        expect(results.first.nombre_completo).to eq('Juan Pérez')
      end
    end
  end
end
