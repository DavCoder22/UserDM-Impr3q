require 'spec_helper'

RSpec.describe 'Perfil API', type: :request do
  let(:user) { create_test_user }
  let(:admin_user) { create_test_user(id: 2, email: 'admin@example.com', role: 'admin') }
  let(:valid_attributes) do
    {
      nombre_completo: 'Juan Pérez',
      correo: 'juan@example.com',
      telefono: '1234567890',
      direccion: 'Calle Falsa 123',
      fecha_nacimiento: '1990-01-01',
      genero: 'M'
    }
  end

  before do
    # Configurar stubs para autenticación
    stub_auth_request(user)
    stub_auth_request(admin_user)
  end

  describe 'GET /api/v1/profile' do
    context 'cuando el usuario tiene un perfil' do
      let!(:profile) { create(:profile, user_id: user[:id], correo: user[:correo]) }

      it 'devuelve el perfil del usuario' do
        get '/api/v1/profile', {}, auth_headers("valid_token_#{user[:id]}")
        
        expect(response).to have_http_status(:ok)
        json = json_response
        expect(json[:nombre_completo]).to eq(profile.nombre_completo)
        expect(json[:correo]).to eq(user[:correo])
      end
    end

    context 'cuando el usuario no tiene perfil' do
      it 'devuelve un error 404' do
        get '/api/v1/profile', {}, auth_headers("valid_token_#{user[:id]}")
        
        expect(response).to have_http_status(:not_found)
        expect(json_response[:error]).to eq('Perfil no encontrado')
      end
    end

    context 'cuando no está autenticado' do
      it 'devuelve un error 401' do
        get '/api/v1/profile'
        
        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq('No autorizado')
      end
    end
  end

  describe 'PUT /api/v1/profile' do
    context 'con atributos válidos' do
      it 'crea un nuevo perfil' do
        expect {
          put '/api/v1/profile', 
              valid_attributes.to_json, 
              auth_headers("valid_token_#{user[:id]}")
        }.to change(Profile, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = json_response
        expect(json[:nombre_completo]).to eq('Juan Pérez')
        expect(json[:correo]).to eq('juan@example.com')
      end

      it 'actualiza un perfil existente' do
        create(:profile, user_id: user[:id])
        
        put '/api/v1/profile', 
            valid_attributes.merge(nombre_completo: 'Nuevo Nombre').to_json, 
            auth_headers("valid_token_#{user[:id]}")
        
        expect(response).to have_http_status(:ok)
        expect(json_response[:nombre_completo]).to eq('Nuevo Nombre')
      end
    end

    context 'con atributos inválidos' do
      it 'devuelve un error 422' do
        put '/api/v1/profile', 
            { nombre_completo: '', correo: 'correo-invalido' }.to_json, 
            auth_headers("valid_token_#{user[:id]}")
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = json_response
        expect(json[:error]).to eq('Error al guardar el perfil')
        expect(json[:details]).to include('nombre_completo no puede estar vacío')
        expect(json[:details]).to include('correo no es un correo válido')
      end
    end
  end

  describe 'PUT /api/v1/profile/avatar' do
    it 'actualiza el avatar del perfil' do
      create(:profile, user_id: user[:id])
      
      put '/api/v1/profile/avatar', 
          { avatar_url: 'http://example.com/avatar.jpg' }.to_json, 
          auth_headers("valid_token_#{user[:id]}")
      
      expect(response).to have_http_status(:ok)
      expect(json_response[:avatar_url]).to eq('http://example.com/avatar.jpg')
    end

    it 'devuelve un error si no se proporciona la URL del avatar' do
      put '/api/v1/profile/avatar', 
          {}.to_json, 
          auth_headers("valid_token_#{user[:id]}")
      
      expect(response).to have_http_status(:bad_request)
      expect(json_response[:error]).to eq('Se requiere la URL del avatar')
    end
  end

  describe 'GET /api/v1/profiles (admin)' do
    before do
      create_list(:profile, 3)
    end

    it 'devuelve una lista de perfiles para administradores' do
      get '/api/v1/profiles', {}, auth_headers("valid_token_#{admin_user[:id]}")
      
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json[:data].size).to eq(3)
      expect(json[:pagination]).to include(
        current_page: 1,
        per_page: 10,
        total_pages: 1,
        total_count: 3
      )
    end

    it 'permite búsqueda por nombre o correo' do
      create(:profile, nombre_completo: 'Usuario Especial', correo: 'especial@example.com')
      
      get '/api/v1/profiles', { q: 'especial' }, auth_headers("valid_token_#{admin_user[:id]}")
      
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json[:data].size).to eq(1)
      expect(json[:data].first[:nombre_completo]).to eq('Usuario Especial')
    end

    it 'permite paginación' do
      get '/api/v1/profiles', { page: 1, per_page: 2 }, auth_headers("valid_token_#{admin_user[:id]}")
      
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json[:data].size).to eq(2)
      expect(json[:pagination]).to include(
        current_page: 1,
        per_page: 2,
        total_pages: 2,
        total_count: 3
      )
    end

    it 'no permite el acceso a usuarios no administradores' do
      get '/api/v1/profiles', {}, auth_headers("valid_token_#{user[:id]}")
      
      expect(response).to have_http_status(:forbidden)
      expect(json_response[:error]).to eq('Acceso denegado')
    end
  end

  describe 'GET /api/v1/profiles/:id (admin)' do
    let!(:profile) { create(:profile) }

    it 'devuelve un perfil específico para administradores' do
      get "/api/v1/profiles/#{profile.id}", {}, auth_headers("valid_token_#{admin_user[:id]}")
      
      expect(response).to have_http_status(:ok)
      expect(json_response[:id]).to eq(profile.id)
      expect(json_response[:nombre_completo]).to eq(profile.nombre_completo)
    end

    it 'devuelve un error 404 si el perfil no existe' do
      get '/api/v1/profiles/9999', {}, auth_headers("valid_token_#{admin_user[:id]}")
      
      expect(response).to have_http_status(:not_found)
      expect(json_response[:error]).to eq('Perfil no encontrado')
    end

    it 'no permite el acceso a usuarios no administradores' do
      get "/api/v1/profiles/#{profile.id}", {}, auth_headers("valid_token_#{user[:id]}")
      
      expect(response).to have_http_status(:forbidden)
      expect(json_response[:error]).to eq('Acceso denegado')
    end
  end
end
