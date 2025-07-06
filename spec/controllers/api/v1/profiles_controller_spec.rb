# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::ProfilesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let!(:profile) { create(:profile, user: user) }
  let(:valid_attributes) do
    {
      first_name: 'Juan',
      last_name: 'Pérez',
      phone: '+34 600 000 000',
      bio: 'Desarrollador de software',
      website: 'https://juanperez.dev',
      company: 'Acme Inc',
      job_title: 'Senior Developer',
      birth_date: '1990-01-01',
      address: 'Calle Falsa 123',
      city: 'Madrid',
      country: 'ES',
      postal_code: '28001',
      twitter_handle: 'juanperez',
      github_username: 'juanperez',
      linkedin_username: 'juanperez',
      instagram_username: 'juanperez',
      public_email: 'juan@juanperez.dev',
      receive_newsletter: true,
      time_zone: 'Madrid',
      locale: 'es',
      metadata: { theme: 'dark', notifications: true }
    }
  end

  let(:invalid_attributes) do
    {
      first_name: '',
      email: 'invalid-email',
      phone: 'invalid-phone',
      website: 'invalid-url',
      birth_date: '3000-01-01' # Fecha futura
    }
  end

  describe 'GET #show' do
    context 'cuando el usuario no está autenticado' do
      before { get :show, params: { id: profile.id } }
      
      it 'devuelve un error de no autorizado' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'cuando el usuario está autenticado' do
      before { api_sign_in(user) }
      
      context 'y solicita su propio perfil' do
        before { get :show, params: { id: profile.id } }
        
        it 'devuelve el perfil solicitado' do
          expect(json_response[:profile][:id]).to eq(profile.id)
          expect(response).to have_http_status(:ok)
        end
      end
      
      context 'y solicita el perfil de otro usuario' do
        let(:other_profile) { create(:profile) }
        before { get :show, params: { id: other_profile.id } }
        
        it 'devuelve un error de prohibido' do
          expect(response).to have_http_status(:forbidden)
        end
      end
      
      context 'y es administrador' do
        before do
          api_sign_in(admin)
          get :show, params: { id: profile.id }
        end
        
        it 'puede ver cualquier perfil' do
          expect(json_response[:profile][:id]).to eq(profile.id)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe 'POST #create' do
    context 'con parámetros válidos' do
      before { api_sign_in(user) }
      
      it 'crea un nuevo perfil' do
        expect {
          post :create, params: { profile: valid_attributes }
        }.to change(Profile, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(json_response[:profile][:first_name]).to eq('Juan')
      end
      
      it 'formatea el número de teléfono' do
        post :create, params: { 
          profile: valid_attributes.merge(phone: ' (123) 456-7890 ') 
        }
        
        expect(json_response[:profile][:phone]).to eq('1234567890')
      end
      
      it 'formatea la URL del sitio web' do
        post :create, params: { 
          profile: valid_attributes.merge(website: 'EJEMPLO.COM') 
        }
        
        expect(json_response[:profile][:website]).to eq('http://ejemplo.com')
      end
    end
    
    context 'con parámetros inválidos' do
      before { api_sign_in(user) }
      
      it 'no crea el perfil y devuelve errores' do
        post :create, params: { profile: invalid_attributes }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors]).to be_present
      end
    end
    
    context 'cuando el usuario ya tiene un perfil' do
      before do
        api_sign_in(user)
        post :create, params: { profile: valid_attributes }
      end
      
      it 'no permite crear otro perfil' do
        expect {
          post :create, params: { profile: valid_attributes }
        }.not_to change(Profile, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    let(:new_attributes) do
      {
        first_name: 'Pedro',
        last_name: 'González',
        phone: '+34 600 111 111',
        bio: 'Diseñador UX/UI',
        website: 'https://pedrogonzalez.design',
        company: 'Design Co',
        job_title: 'Lead Designer',
        birth_date: '1985-05-15',
        address: 'Avenida Real 456',
        city: 'Barcelona',
        country: 'ES',
        postal_code: '08001',
        twitter_handle: 'pedrogonzalez',
        github_username: 'pedrogonzalez',
        linkedin_username: 'pedrogonzalez',
        instagram_username: 'pedrogonzalez',
        public_email: 'pedro@pedrogonzalez.design',
        receive_newsletter: false,
        time_zone: 'Barcelona',
        locale: 'ca',
        metadata: { theme: 'light', notifications: false }
      }
    end

    context 'cuando el usuario actualiza su propio perfil' do
      before { api_sign_in(user) }
      
      context 'con parámetros válidos' do
        before do
          put :update, params: { id: profile.id, profile: new_attributes }
        end
        
        it 'actualiza el perfil' do
          profile.reload
          expect(profile.first_name).to eq('Pedro')
          expect(profile.last_name).to eq('González')
          expect(profile.city).to eq('Barcelona')
          expect(response).to have_http_status(:ok)
        end
        
        it 'formatea el número de teléfono' do
          put :update, params: { 
            id: profile.id, 
            profile: { phone: ' (123) 456-7890 ' } 
          }
          
          expect(profile.reload.phone).to eq('1234567890')
        end
      end
      
      context 'con parámetros inválidos' do
        before do
          put :update, params: { 
            id: profile.id, 
            profile: { website: 'invalid-url' } 
          }
        end
        
        it 'no actualiza el perfil' do
          expect(profile.reload.website).not_to eq('invalid-url')
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response[:errors]).to be_present
        end
      end
    end
    
    context 'cuando un usuario intenta actualizar otro perfil' do
      let(:other_profile) { create(:profile) }
      
      before do
        api_sign_in(user)
        put :update, params: { 
          id: other_profile.id, 
          profile: { first_name: 'Nuevo Nombre' } 
        }
      end
      
      it 'devuelve un error de prohibido' do
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context 'cuando un administrador actualiza cualquier perfil' do
      before do
        api_sign_in(admin)
        put :update, params: { 
          id: profile.id, 
          profile: { first_name: 'Admin Updated' } 
        }
      end
      
      it 'actualiza el perfil exitosamente' do
        expect(profile.reload.first_name).to eq('Admin Updated')
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'cuando el usuario elimina su propio perfil' do
      before { api_sign_in(user) }
      
      it 'elimina el perfil' do
        expect {
          delete :destroy, params: { id: profile.id }
        }.to change(Profile, :count).by(-1)
        
        expect(response).to have_http_status(:no_content)
      end
    end
    
    context 'cuando un usuario intenta eliminar otro perfil' do
      let!(:other_profile) { create(:profile) }
      
      before do
        api_sign_in(user)
        delete :destroy, params: { id: other_profile.id }
      end
      
      it 'devuelve un error de prohibido' do
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context 'cuando un administrador elimina cualquier perfil' do
      before { api_sign_in(admin) }
      
      it 'elimina el perfil exitosamente' do
        expect {
          delete :destroy, params: { id: profile.id }
        }.to change(Profile, :count).by(-1)
        
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe 'GET #me' do
    before { api_sign_in(user) }
    
    it 'devuelve el perfil del usuario actual' do
      get :me
      
      expect(json_response[:profile][:id]).to eq(profile.id)
      expect(response).to have_http_status(:ok)
    end
    
    it 'incluye información del usuario relacionado' do
      get :me
      
      expect(json_response[:profile][:user][:id]).to eq(user.id)
      expect(json_response[:profile][:user][:email]).to eq(user.email)
    end
  end

  describe 'POST #upload_avatar' do
    let(:image_path) { Rails.root.join('spec', 'fixtures', 'files', 'avatar.jpg') }
    let(:image) { fixture_file_upload(image_path, 'image/jpeg') }
    
    before { api_sign_in(user) }
    
    context 'con una imagen válida' do
      it 'sube el avatar correctamente' do
        expect {
          post :upload_avatar, params: { id: profile.id, avatar: image }
        }.to change(ActiveStorage::Attachment, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        expect(profile.reload.avatar).to be_attached
      end
    end
    
    context 'con un archivo inválido' do
      let(:invalid_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.txt'), 'text/plain') }
      
      it 'no sube el archivo y devuelve un error' do
        post :upload_avatar, params: { id: profile.id, avatar: invalid_file }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors]).to include('El archivo debe ser una imagen (JPG, PNG o GIF)')
      end
    end
    
    context 'con un archivo demasiado grande' do
      before do
        allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(6.megabytes)
      end
      
      it 'rechaza el archivo y devuelve un error' do
        post :upload_avatar, params: { id: profile.id, avatar: image }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors]).to include('El archivo no puede superar los 5MB')
      end
    end
  end

  describe 'DELETE #remove_avatar' do
    let(:image_path) { Rails.root.join('spec', 'fixtures', 'files', 'avatar.jpg') }
    
    before do
      api_sign_in(user)
      profile.avatar.attach(io: File.open(image_path), filename: 'avatar.jpg')
    end
    
    it 'elimina el avatar del perfil' do
      expect(profile.avatar).to be_attached
      
      delete :remove_avatar, params: { id: profile.id }
      
      expect(response).to have_http_status(:no_content)
      expect(profile.reload.avatar).not_to be_attached
    end
  end

  describe 'GET #search' do
    let!(:profile1) { create(:profile, first_name: 'Juan', last_name: 'Pérez', bio: 'Desarrollador Ruby') }
    let!(:profile2) { create(:profile, first_name: 'Ana', last_name: 'Gómez', bio: 'Diseñadora UX') }
    let!(:profile3) { create(:profile, first_name: 'Carlos', last_name: 'López', bio: 'Desarrollador JavaScript') }
    
    before { api_sign_in(admin) } # Solo administradores pueden buscar
    
    it 'busca perfiles por nombre' do
      get :search, params: { q: 'Juan' }
      
      expect(json_response[:profiles].size).to eq(1)
      expect(json_response[:profiles].first[:id]).to eq(profile1.id)
    end
    
    it 'busca perfiles por apellido' do
      get :search, params: { q: 'Gómez' }
      
      expect(json_response[:profiles].size).to eq(1)
      expect(json_response[:profiles].first[:id]).to eq(profile2.id)
    end
    
    it 'busca perfiles por biografía' do
      get :search, params: { q: 'Desarrollador' }
      
      expect(json_response[:profiles].size).to eq(2)
      expect(json_response[:profiles].map { |p| p[:id] }).to include(profile1.id, profile3.id)
    end
    
    it 'devuelve un array vacío si no hay coincidencias' do
      get :search, params: { q: 'inexistente' }
      
      expect(json_response[:profiles]).to be_empty
    end
    
    it 'devuelve un error si el usuario no es administrador' do
      api_sign_in(user)
      get :search, params: { q: 'cualquier cosa' }
      
      expect(response).to have_http_status(:forbidden)
    end
  end

  private

  def api_sign_in(user)
    request.headers['Authorization'] = "Bearer #{user.auth_token}"
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
