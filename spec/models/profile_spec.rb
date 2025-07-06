# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile, type: :model do
  let(:user) { create(:user) }
  let(:profile) { build(:profile, user: user) }
  
  describe 'validaciones' do
    it 'es válido con atributos válidos' do
      expect(profile).to be_valid
    end
    
    it 'es inválido sin usuario' do
      profile.user = nil
      expect(profile).not_to be_valid
      expect(profile.errors[:user]).to include('debe existir')
    end
    
    describe 'validación de teléfono' do
      it 'acepta números de teléfono válidos' do
        valid_phones = [
          '+1 (555) 123-4567',
          '+34 91 123 45 67',
          '912345678',
          '123-456-7890',
          '(123) 456-7890',
          '123.456.7890',
          '123 456 7890'
        ]
        
        valid_phones.each do |phone|
          profile.phone = phone
          expect(profile).to be_valid, "Se esperaba que #{phone} fuera un teléfono válido"
        end
      end
      
      it 'rechaza números de teléfono inválidos' do
        invalid_phones = [
          'abc',
          '123',
          '123-abc-4567',
          '1-800-HELLO',
          '12345678901234567890',
          ''
        ]
        
        invalid_phones.each do |phone|
          profile.phone = phone
          expect(profile).not_to be_valid, "Se esperaba que #{phone} fuera un teléfono inválido"
          expect(profile.errors[:phone]).to include('no es un número de teléfono válido')
        end
      end
      
      it 'permite valores nulos' do
        profile.phone = nil
        expect(profile).to be_valid
      end
    end
    
    describe 'validación de sitio web' do
      it 'acepta URLs válidas' do
        valid_urls = [
          'http://example.com',
          'https://www.example.com',
          'http://sub.dominio.ejemplo.com/ruta?param=valor',
          'www.ejemplo.com',
          'ejemplo.com'
        ]
        
        valid_urls.each do |url|
          profile.website = url
          expect(profile).to be_valid, "Se esperaba que #{url} fuera una URL válida"
        end
      end
      
      it 'rechaza URLs inválidas' do
        invalid_urls = [
          'no-es-una-url',
          'htp://mal-formado.com',
          'http://',
          'http://espacio enblanco.com',
          'javascript:alert(1)'
        ]
        
        invalid_urls.each do |url|
          profile.website = url
          expect(profile).not_to be_valid, "Se esperaba que #{url} fuera una URL inválida"
          expect(profile.errors[:website]).to include('no es una URL válida')
        end
      end
      
      it 'permite valores nulos' do
        profile.website = nil
        expect(profile).to be_valid
      end
    end
    
    describe 'validación de fecha de nacimiento' do
      it 'acepta fechas pasadas' do
        profile.birth_date = 30.years.ago
        expect(profile).to be_valid
      end
      
      it 'rechaza fechas futuras' do
        profile.birth_date = 1.day.from_now
        expect(profile).not_to be_valid
        expect(profile.errors[:birth_date]).to include('no puede ser en el futuro')
      end
      
      it 'rechaza fechas muy antiguas' do
        profile.birth_date = 200.years.ago
        expect(profile).not_to be_valid
        expect(profile.errors[:birth_date]).to include('no puede ser antes de 1900')
      end
      
      it 'permite valores nulos' do
        profile.birth_date = nil
        expect(profile).to be_valid
      end
    end
  end
  
  describe 'callbacks' do
    it 'formatea el número de teléfono antes de la validación' do
      profile.phone = ' (123) 456-7890 '
      profile.valid?
      expect(profile.phone).to eq('1234567890')
    end
    
    it 'formatea la URL antes de la validación' do
      profile.website = '  EJEMPLO.COM/path?param=value  '
      profile.valid?
      expect(profile.website).to eq('http://ejemplo.com/path?param=value')
    end
    
    it 'calcula la edad a partir de la fecha de nacimiento' do
      profile.birth_date = 25.years.ago.to_date
      profile.save
      expect(profile.age).to be_within(1).of(25)
    end
  end
  
  describe 'métodos de instancia' do
    describe '#full_name' do
      it 'combina nombre y apellido' do
        profile.first_name = 'Juan'
        profile.last_name = 'Pérez'
        expect(profile.full_name).to eq('Juan Pérez')
      end
      
      it 'manja valores nulos' do
        profile.first_name = nil
        profile.last_name = 'Pérez'
        expect(profile.full_name).to eq('Pérez')
        
        profile.first_name = 'Juan'
        profile.last_name = nil
        expect(profile.full_name).to eq('Juan')
      end
    end
    
    describe '#age' do
      it 'calcula la edad correctamente' do
        profile.birth_date = Date.new(1990, 1, 1)
        travel_to Date.new(2023, 1, 1) do
          expect(profile.age).to eq(33)
        end
      end
      
      it 'devuelve nil si no hay fecha de nacimiento' do
        profile.birth_date = nil
        expect(profile.age).to be_nil
      end
    end
    
    describe '#location' do
      it 'combina ciudad y país' do
        profile.city = 'Madrid'
        profile.country = 'España'
        expect(profile.location).to eq('Madrid, España')
      end
      
      it 'devuelve solo la ciudad si no hay país' do
        profile.city = 'Buenos Aires'
        profile.country = nil
        expect(profile.location).to eq('Buenos Aires')
      end
      
      it 'devuelve solo el país si no hay ciudad' do
        profile.city = nil
        profile.country = 'México'
        expect(profile.location).to eq('México')
      end
      
      it 'devuelve nil si no hay ciudad ni país' do
        profile.city = nil
        profile.country = nil
        expect(profile.location).to be_nil
      end
    end
  end
  
  describe 'asociaciones' do
    it 'pertenece a un usuario' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
    
    it 'tiene un avatar adjunto' do
      expect(profile).to respond_to(:avatar)
      expect(profile.avatar).to be_an_instance_of(ActiveStorage::Attached::One)
    end
  end
  
  describe 'métodos de búsqueda' do
    let!(:profile1) { create(:profile, first_name: 'Juan', last_name: 'Pérez', bio: 'Desarrollador Ruby') }
    let!(:profile2) { create(:profile, first_name: 'Ana', last_name: 'Gómez', bio: 'Diseñadora UX') }
    let!(:profile3) { create(:profile, first_name: 'Carlos', last_name: 'López', bio: 'Desarrollador JavaScript') }
    
    describe '.search' do
      it 'busca perfiles por nombre' do
        results = described_class.search('Juan')
        expect(results).to include(profile1)
        expect(results).not_to include(profile2, profile3)
      end
      
      it 'busca perfiles por apellido' do
        results = described_class.search('Gómez')
        expect(results).to include(profile2)
        expect(results).not_to include(profile1, profile3)
      end
      
      it 'busca perfiles por biografía' do
        results = described_class.search('Desarrollador')
        expect(results).to include(profile1, profile3)
        expect(results).not_to include(profile2)
      end
      
      it 'devuelve resultados insensibles a mayúsculas/minúsculas' do
        results = described_class.search('ruby')
        expect(results).to include(profile1)
      end
      
      it 'devuelve una relación vacía si no hay coincidencias' do
        results = described_class.search('inexistente')
        expect(results).to be_empty
      end
    end
  end
  
  describe 'métodos de clase' do
    describe '.age_ranges' do
      it 'devuelve rangos de edad predefinidos' do
        expect(described_class.age_ranges).to be_an(Array)
        expect(described_class.age_ranges.first).to eq(['Menos de 18', '0-17'])
        expect(described_class.age_ranges.last).to eq(['65 o más', '65-120'])
      end
    end
    
    describe '.countries' don      it 'devuelve una lista de países' do
        expect(described_class.countries).to be_an(Array)
        expect(described_class.countries).to include(['España', 'ES'])
        expect(described_class.countries).to include(['México', 'MX'])
      end
    end
  end
  
  describe 'métodos de instancia protegidos' do
    describe '#format_phone' do
      it 'elimina caracteres no numéricos' do
        profile.phone = ' (123) 456-7890 '
        profile.send(:format_phone)
        expect(profile.phone).to eq('1234567890')
      end
      
      it 'no hace nada si el teléfono es nil' do
        profile.phone = nil
        expect { profile.send(:format_phone) }.not_to raise_error
      end
    end
    
    describe '#format_website' do
      it 'agrega http:// si es necesario' do
        profile.website = 'ejemplo.com'
        profile.send(:format_website)
        expect(profile.website).to eq('http://ejemplo.com')
      end
      
      it 'no modifica URLs que ya tienen protocolo' do
        profile.website = 'https://ejemplo.com'
        profile.send(:format_website)
        expect(profile.website).to eq('https://ejemplo.com')
      end
      
      it 'convierte a minúsculas' do
        profile.website = 'EJEMPLO.COM'
        profile.send(:format_website)
        expect(profile.website).to eq('http://ejemplo.com')
      end
      
      it 'elimina espacios en blanco' do
        profile.website = '  ejemplo.com  '
        profile.send(:format_website)
        expect(profile.website).to eq('http://ejemplo.com')
      end
      
      it 'no hace nada si el sitio web es nil' do
        profile.website = nil
        expect { profile.send(:format_website) }.not_to raise_error
      end
    end
  end
  
  describe 'métodos de instancia privados' do
    describe '#calculate_age' do
      it 'calcula la edad correctamente' do
        profile.birth_date = Date.new(1990, 1, 1)
        travel_to Date.new(2023, 1, 1) do
          expect(profile.send(:calculate_age)).to eq(33)
        end
      end
      
      it 'devuelve nil si no hay fecha de nacimiento' do
        profile.birth_date = nil
        expect(profile.send(:calculate_age)).to be_nil
      end
    end
  end
  
  describe 'pruebas de integración con Active Storage' do
    let(:image_path) { Rails.root.join('spec', 'fixtures', 'files', 'avatar.jpg') }
    
    it 'adjunta una imagen correctamente' do
      profile.avatar.attach(
        io: File.open(image_path),
        filename: 'avatar.jpg',
        content_type: 'image/jpeg'
      )
      
      expect(profile.avatar).to be_attached
      expect(profile.avatar.filename).to eq('avatar.jpg')
      expect(profile.avatar.content_type).to eq('image/jpeg')
    end
    
    it 'valida el tipo de archivo' do
      invalid_file = StringIO.new('invalid')
      
      profile.avatar.attach(
        io: invalid_file,
        filename: 'test.txt',
        content_type: 'text/plain'
      )
      
      expect(profile).not_to be_valid
      expect(profile.errors[:avatar]).to include('debe ser una imagen (JPG, PNG o GIF)')
    end
    
    it 'valida el tamaño del archivo' do
      large_file = StringIO.new('a' * 6.megabytes)
      
      profile.avatar.attach(
        io: large_file,
        filename: 'large.jpg',
        content_type: 'image/jpeg'
      )
      
      expect(profile).not_to be_valid
      expect(profile.errors[:avatar]).to include('no puede superar los 5MB')
    end
  end
  
  describe 'pruebas de rendimiento' do
    it 'carga perfiles de manera eficiente' do
      create_list(:profile, 50)
      
      expect {
        Profile.includes(:user).all.map(&:user_email)
      }.to perform_under(50).ms
    end
  end
end
