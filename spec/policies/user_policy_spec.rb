# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }
  
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:other_user) { create(:user) }
  
  permissions :index? do
    it 'permite al administrador ver la lista de usuarios' do
      expect(subject).to permit(admin, User)
    end
    
    it 'no permite a los usuarios regulares ver la lista de usuarios' do
      expect(subject).not_to permit(regular_user, User)
    end
    
    it 'no permite a los invitados ver la lista de usuarios' do
      expect(subject).not_to permit(nil, User)
    end
  end
  
  permissions :show? do
    it 'permite a los usuarios ver su propio perfil' do
      expect(subject).to permit(regular_user, regular_user)
    end
    
    it 'permite al administrador ver cualquier perfil' do
      expect(subject).to permit(admin, regular_user)
    end
    
    it 'no permite a un usuario ver el perfil de otro usuario' do
      expect(subject).not_to permit(regular_user, other_user)
    end
    
    it 'no permite a los invitados ver perfiles' do
      expect(subject).not_to permit(nil, regular_user)
    end
  end
  
  permissions :create? do
    it 'permite a cualquiera crear una cuenta' do
      expect(subject).to permit(nil, User.new)
    end
    
    it 'permite a los administradores crear usuarios' do
      expect(subject).to permit(admin, User.new)
    end
  end
  
  permissions :update? do
    it 'permite a los usuarios actualizar su propio perfil' do
      expect(subject).to permit(regular_user, regular_user)
    end
    
    it 'permite a los administradores actualizar cualquier perfil' do
      expect(subject).to permit(admin, regular_user)
    end
    
    it 'no permite a un usuario actualizar el perfil de otro usuario' do
      expect(subject).not_to permit(regular_user, other_user)
    end
    
    it 'no permite a los invitados actualizar perfiles' do
      expect(subject).not_to permit(nil, regular_user)
    end
  end
  
  permissions :destroy? do
    it 'permite a los administradores eliminar usuarios' do
      expect(subject).to permit(admin, regular_user)
    end
    
    it 'permite a los usuarios eliminar su propia cuenta' do
      expect(subject).to permit(regular_user, regular_user)
    end
    
    it 'no permite a un usuario eliminar la cuenta de otro usuario' do
      expect(subject).not_to permit(regular_user, other_user)
    end
    
    it 'no permite a los invitados eliminar cuentas' do
      expect(subject).not_to permit(nil, regular_user)
    end
  end
  
  permissions :deactivate? do
    it 'permite a los administradores desactivar usuarios' do
      expect(subject).to permit(admin, regular_user)
    end
    
    it 'no permite a los usuarios regulares desactivar cuentas' do
      expect(subject).not_to permit(regular_user, other_user)
    end
    
    it 'no permite a los usuarios desactivar su propia cuenta' do
      expect(subject).not_to permit(regular_user, regular_user)
    end
  end
  
  permissions :reactivate? do
    let(:inactive_user) { create(:user, :inactive) }
    
    it 'permite a los administradores reactivar usuarios' do
      expect(subject).to permit(admin, inactive_user)
    end
    
    it 'no permite a los usuarios regulares reactivar cuentas' do
      expect(subject).not_to permit(regular_user, inactive_user)
    end
  end
  
  describe 'scope' do
    let!(:active_user) { create(:user) }
    let!(:inactive_user) { create(:user, :inactive) }
    let!(:admin_user) { create(:user, :admin) }
    
    context 'para administradores' do
      let(:scope) { Pundit.policy_scope!(admin, User) }
      
      it 'incluye todos los usuarios' do
        expect(scope).to include(active_user, inactive_user, admin_user, admin)
      end
    end
    
    context 'para usuarios regulares' do
      let(:scope) { Pundit.policy_scope!(regular_user, User) }
      
      it 'solo incluye al propio usuario' do
        expect(scope).to contain_exactly(regular_user)
      end
    end
    
    context 'para invitados' do
      let(:scope) { Pundit.policy_scope!(nil, User) }
      
      it 'está vacío' do
        expect(scope).to be_empty
      end
    end
  end
  
  describe 'atributos permitidos' do
    context 'para administradores' do
      let(:policy) { UserPolicy.new(admin, User.new) }
      
      it 'permite todos los atributos' do
        expect(policy.permitted_attributes).to eq([
          :name, :email, :password, :password_confirmation, :current_password,
          :role, :active, :phone, :time_zone, :preferred_language
        ])
      end
    end
    
    context 'para usuarios regulares' do
      let(:policy) { UserPolicy.new(regular_user, User.new) }
      
      it 'solo permite ciertos atributos' do
        expect(policy.permitted_attributes).to eq([
          :name, :email, :password, :password_confirmation, :current_password,
          :phone, :time_zone, :preferred_language
        ])
      end
    end
    
    context 'para registro de nuevos usuarios' do
      let(:policy) { UserPolicy.new(nil, User.new) }
      
      it 'solo permite atributos básicos' do
        expect(policy.permitted_attributes_for_create).to eq([
          :name, :email, :password, :password_confirmation
        ])
      end
    end
  end
  
  describe 'métodos personalizados' do
    let(:policy) { UserPolicy.new(admin, regular_user) }
    
    it 'puede_ver_actividad?' do
      expect(policy.can_view_activity?).to be_truthy
      
      user_policy = UserPolicy.new(regular_user, other_user)
      expect(user_policy.can_view_activity?).to be_falsey
    end
    
    it 'puede_eliminar_permanentemente?' do
      expect(policy.can_permanently_delete?).to be_truthy
      
      user_policy = UserPolicy.new(regular_user, regular_user)
      expect(user_policy.can_permanently_delete?).to be_falsey
    end
  end
  
  describe 'métodos de ámbito personalizados' do
    let!(:active_users) { create_list(:user, 2) }
    let!(:inactive_users) { create_list(:user, 1, :inactive) }
    let!(:admin_users) { create_list(:user, 1, :admin) }
    
    it 'resuelve el ámbito activo' do
      scope = UserPolicy::Scope.new(admin, User).resolve
      expect(scope.where(active: true).count).to eq(active_users.count + admin_users.count)
    end
    
    it 'resuelve el ámbito inactivo' do
      scope = UserPolicy::Scope.new(admin, User.inactive).resolve
      expect(scope.count).to eq(inactive_users.count)
    end
  end
  
  describe 'métodos de verificación de roles' do
    it 'admin?' do
      expect(UserPolicy.new(admin, User).admin?).to be_truthy
      expect(UserPolicy.new(regular_user, User).admin?).to be_falsey
    end
    
    it 'es_propio_usuario?' do
      expect(UserPolicy.new(regular_user, regular_user).es_propio_usuario?).to be_truthy
      expect(UserPolicy.new(regular_user, other_user).es_propio_usuario?).to be_falsey
    end
  end
  
  describe 'manejo de excepciones' do
    it 'maneja usuarios nulos' do
      policy = UserPolicy.new(nil, regular_user)
      expect { policy.show? }.not_to raise_error
      expect(policy.show?).to be_falsey
    end
    
    it 'maneja recursos nulos' do
      policy = UserPolicy.new(regular_user, nil)
      expect { policy.show? }.not_to raise_error
      expect(policy.show?).to be_falsey
    end
  end
end
