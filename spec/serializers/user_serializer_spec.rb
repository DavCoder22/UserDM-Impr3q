# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserSerializer, type: :serializer do
  let(:user) { create(:user, :with_profile) }
  let(:serializer) { described_class.new(user) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).to_json }
  let(:serialized_user) { JSON.parse(serialization) }
  
  describe 'atributos principales' do
    it 'incluye el ID del usuario' do
      expect(serialized_user['user']['id']).to eq(user.id)
    end
    
    it 'incluye el email del usuario' do
      expect(serialized_user['user']['email']).to eq(user.email)
    end
    
    it 'incluye el nombre del usuario' do
      expect(serialized_user['user']['name']).to eq(user.name)
    end
    
    it 'incluye la fecha de creación' do
      expect(serialized_user['user']['created_at']).to be_present
    end
    
    it 'no incluye la contraseña' do
      expect(serialized_user['user']).not_to have_key('password')
      expect(serialized_user['user']).not_to have_key('password_digest')
      expect(serialized_user['user']).not_to have_key('password_confirmation')
    end
    
    it 'no incluye el token de reinicio de contraseña' do
      expect(serialized_user['user']).not_to have_key('reset_password_token')
    end
  end
  
  describe 'atributos condicionales' do
    context 'cuando se incluye el perfil' do
      before do
        user.create_profile!(
          bio: 'Desarrollador de software',
          website: 'https://example.com',
          location: 'Ciudad, País',
          birth_date: 30.years.ago.to_date
        )
      end
      
      let(:serializer) { described_class.new(user, include: [:profile]) }
      let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).to_json }
      
      it 'incluye el perfil del usuario' do
        expect(serialized_user['user']).to have_key('profile')
        expect(serialized_user['user']['profile']['bio']).to eq('Desarrollador de software')
      end
    end
    
    context 'cuando no se incluye el perfil' do
      it 'no incluye el perfil del usuario' do
        expect(serialized_user['user']).not_to have_key('profile')
      end
    end
  end
  
  describe 'relaciones' do
    let!(:post) { create(:post, user: user) }
    let!(:comment) { create(:comment, user: user, post: post) }
    
    context 'cuando se incluyen las publicaciones' do
      let(:serializer) { described_class.new(user, include: [:posts]) }
      let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).to_json }
      
      it 'incluye las publicaciones del usuario' do
        expect(serialized_user['user']).to have_key('posts')
        expect(serialized_user['user']['posts'].first['id']).to eq(post.id)
      end
    end
    
    context 'cuando se incluyen los comentarios' do
      let(:serializer) { described_class.new(user, include: [:comments]) }
      let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).to_json }
      
      it 'incluye los comentarios del usuario' do
        expect(serialized_user['user']).to have_key('comments')
        expect(serialized_user['user']['comments'].first['id']).to eq(comment.id)
      end
    end
  end
  
  describe 'métodos personalizados' do
    it 'incluye el nombre completo' do
      user.update(first_name: 'John', last_name: 'Doe')
      expect(serialized_user['user']['full_name']).to eq('John Doe')
    end
    
    it 'incluye el rol formateado' do
      user.update(role: 'admin')
      expect(serialized_user['user']['role']).to eq('Administrador')
    end
    
    it 'incluye el estado de la cuenta' do
      expect(serialized_user['user']['status']).to eq('active')
      
      user.update(active: false)
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(user.reload)).to_json
      serialized_user = JSON.parse(serialization)
      
      expect(serialized_user['user']['status']).to eq('inactive')
    end
  end
  
  describe 'seguridad' do
    it 'no filtra atributos sensibles' do
      sensitive_attributes = %w[
        reset_password_token
        reset_password_sent_at
        remember_created_at
        sign_in_count
        current_sign_in_at
        last_sign_in_at
        current_sign_in_ip
        last_sign_in_ip
        confirmation_token
        confirmed_at
        confirmation_sent_at
        unconfirmed_email
        failed_attempts
        unlock_token
        locked_at
      ]
      
      sensitive_attributes.each do |attr|
        expect(serialized_user['user']).not_to have_key(attr)
      end
    end
  end
  
  describe 'formato de fechas' do
    it 'formatea las fechas en ISO 8601' do
      expect(serialized_user['user']['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/)
      expect(serialized_user['user']['updated_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/)
    end
  end
  
  describe 'rendering anidado' do
    let!(:post) { create(:post, user: user) }
    let(:serializer) { described_class.new(user, include: ['posts.comments']) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).to_json }
    
    it 'soporta anidamiento profundo' do
      expect(serialized_user['user']['posts'].first).to have_key('comments')
    end
  end
  
  describe 'personalización de campos' do
    context 'cuando se solicitan campos específicos' do
      let(:serializer) { described_class.new(user, fields: [:id, :email]) }
      let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).to_json }
      
      it 'solo incluye los campos solicitados' do
        expect(serialized_user['user'].keys).to contain_exactly('id', 'email')
      end
    end
  end
  
  describe 'versión de la API' do
    context 'con la versión 2 de la API' do
      let(:serializer) { described_class.new(user, scope: { api_version: 'v2' }) }
      
      it 'incluye campos adicionales para v2' do
        expect(serialized_user['user']).to have_key('preferences')
      end
    end
  end
  
  describe 'serialización de colecciones' do
    let!(:users) { create_list(:user, 3) }
    let(:serializer) { ActiveModel::Serializer::CollectionSerializer.new(users, serializer: described_class) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).to_json }
    let(:parsed_response) { JSON.parse(serialization) }
    
    it 'serializa correctamente una colección de usuarios' do
      expect(parsed_response['users'].count).to eq(3)
      expect(parsed_response['users'].first).to have_key('id')
      expect(parsed_response['users'].first).to have_key('email')
    end
  end
  
  describe 'manejo de errores' do
    it 'maneja usuarios nulos' do
      serializer = described_class.new(nil)
      serialization = ActiveModelSerializers::Adapter.create(serializer).to_json
      parsed_response = JSON.parse(serialization)
      
      expect(parsed_response['user']).to be_nil
    end
  end
  
  describe 'rendering de errores' do
    before { user.email = 'invalid-email' }
    
    it 'incluye errores de validación cuando el usuario no es válido' do
      expect(user).to be_invalid
      
      serializer = described_class.new(user)
      serialization = ActiveModelSerializers::Adapter.create(serializer).to_json
      parsed_response = JSON.parse(serialization)
      
      expect(parsed_response['user']['errors']).to be_present
      expect(parsed_response['user']['errors']['email']).to include('no es un email válido')
    end
  end
  
  describe 'serialización de metadatos' do
    it 'incluye metadatos de paginación cuando corresponde' do
      users = create_list(:user, 25)
      paginated = users.paginate(page: 1, per_page: 10)
      
      serializer = ActiveModel::Serializer::CollectionSerializer.new(
        paginated, 
        each_serializer: described_class
      )
      
      options = {
        meta: {
          current_page: 1,
          total_pages: 3,
          total_count: 25,
          per_page: 10
        },
        meta_key: :pagination
      }
      
      serialization = ActiveModelSerializers::Adapter.create(
        serializer,
        adapter: :json,
        meta: options[:meta],
        meta_key: options[:meta_key]
      ).to_json
      
      parsed_response = JSON.parse(serialization)
      
      expect(parsed_response['pagination']).to be_present
      expect(parsed_response['pagination']['current_page']).to eq(1)
      expect(parsed_response['pagination']['total_pages']).to eq(3)
      expect(parsed_response['pagination']['total_count']).to eq(25)
    end
  end
end
