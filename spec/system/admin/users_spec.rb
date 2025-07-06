# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Users', type: :system, js: true do
  let(:admin) { create(:user, :admin) }
  let!(:user) { create(:user) }
  let!(:inactive_user) { create(:user, :inactive) }
  let!(:unconfirmed_user) { create(:user, :unconfirmed) }
  
  before do
    driven_by(:selenium_chrome_headless)
    login_as(admin, scope: :user)
    visit admin_users_path
  end
  
  describe 'Lista de usuarios' do
    it 'muestra todos los usuarios' do
      expect(page).to have_content(admin.email)
      expect(page).to have_content(user.email)
      expect(page).to have_content(inactive_user.email)
      expect(page).to have_content(unconfirmed_user.email)
    end
    
    it 'permite filtrar usuarios por estado' do
      select 'Activos', from: 'status'
      click_button 'Filtrar'
      
      expect(page).to have_content(admin.email)
      expect(page).to have_content(user.email)
      expect(page).not_to have_content(inactive_user.email)
      
      select 'Inactivos', from: 'status'
      click_button 'Filtrar'
      
      expect(page).to have_content(inactive_user.email)
      expect(page).not_to have_content(admin.email)
    end
    
    it 'permite buscar usuarios por email' do
      fill_in 'search', with: user.email
      click_button 'Buscar'
      
      expect(page).to have_content(user.email)
      expect(page).not_to have_content(admin.email)
    end
    
    it 'muestra el número total de usuarios' do
      expect(page).to have_content("Mostrando 4 de 4 usuarios")
    end
  end
  
  describe 'Ver detalles de un usuario' do
    it 'muestra los detalles completos del usuario' do
      within "tr#user-#{user.id}" do
        click_link 'Ver'
      end
      
      expect(page).to have_content("Detalles de #{user.email}")
      expect(page).to have_content(user.created_at.strftime('%d/%m/%Y'))
      expect(page).to have_content(user.last_sign_in_at ? user.last_sign_in_at.strftime('%d/%m/%Y %H:%M') : 'Nunca')
    end
  end
  
  describe 'Editar usuario' do
    before do
      within "tr#user-#{user.id}" do
        click_link 'Editar'
      end
    end
    
    it 'permite actualizar la información del usuario' do
      fill_in 'Nombre', with: 'Nuevo Nombre'
      fill_in 'Apellido', with: 'Nuevo Apellido'
      select 'Administrador', from: 'Rol'
      
      click_button 'Actualizar Usuario'
      
      expect(page).to have_content('Usuario actualizado correctamente')
      expect(user.reload.name).to eq('Nuevo Nombre')
      expect(user.last_name).to eq('Nuevo Apellido')
      expect(user).to be_admin
    end
    
    it 'muestra errores de validación' do
      fill_in 'Email', with: ''
      click_button 'Actualizar Usuario'
      
      expect(page).to have_content('no puede estar en blanco')
    end
  end
  
  describe 'Desactivar/Activar usuario' do
    it 'permite desactivar un usuario activo' do
      within "tr#user-#{user.id}" do
        accept_confirm { click_link 'Desactivar' }
      end
      
      expect(page).to have_content('Usuario desactivado correctamente')
      expect(user.reload).not_to be_active
    end
    
    it 'permite activar un usuario inactivo' do
      within "tr#user-#{inactive_user.id}" do
        accept_confirm { click_link 'Activar' }
      end
      
      expect(page).to have_content('Usuario activado correctamente')
      expect(inactive_user.reload).to be_active
    end
  end
  
  describe 'Eliminar usuario' do
    it 'permite eliminar un usuario' do
      within "tr#user-#{user.id}" do
        accept_confirm { click_link 'Eliminar' }
      end
      
      expect(page).to have_content('Usuario eliminado correctamente')
      expect(User.exists?(user.id)).to be_falsey
    end
    
    it 'no permite eliminar el propio usuario administrador' do
      within "tr#user-#{admin.id}" do
        expect(page).not_to have_link('Eliminar')
      end
    end
  end
  
  describe 'Crear nuevo usuario' do
    before do
      click_link 'Nuevo Usuario'
    end
    
    it 'permite crear un nuevo usuario' do
      fill_in 'Email', with: 'nuevo@usuario.com'
      fill_in 'Contraseña', with: 'password123'
      fill_in 'Confirmar Contraseña', with: 'password123'
      fill_in 'Nombre', with: 'Nuevo'
      fill_in 'Apellido', with: 'Usuario'
      select 'Usuario', from: 'Rol'
      
      expect {
        click_button 'Crear Usuario'
      }.to change(User, :count).by(1)
      
      expect(page).to have_content('Usuario creado correctamente')
      expect(User.last.email).to eq('nuevo@usuario.com')
    end
    
    it 'muestra errores de validación' do
      click_button 'Crear Usuario'
      
      expect(page).to have_content('no puede estar en blanco')
    end
  end
  
  describe 'Paginación' do
    before do
      # Crear suficientes usuarios para probar la paginación
      create_list(:user, 15)
      visit admin_users_path
    end
    
    it 'muestra la paginación cuando hay más de 10 usuarios' do
      expect(page).to have_selector('.pagination')
    end
    
    it 'permite navegar entre páginas' do
      expect(page).to have_selector('table tbody tr', count: 10) # 10 por página
      
      click_link 'Siguiente'
      
      # Verificar que estamos en la segunda página
      expect(page).to have_selector('table tbody tr', count: 9) # 9 usuarios restantes (19 total - 10 en la primera página)
    end
  end
  
  describe 'Exportación de datos' do
    it 'permite exportar usuarios a CSV' do
      click_link 'Exportar CSV'
      
      expect(page.response_headers['Content-Type']).to eq('text/csv')
      expect(page.response_headers['Content-Disposition']).to include('users_export_')
    end
    
    it 'permite exportar usuarios a Excel' do
      click_link 'Exportar Excel'
      
      expect(page.response_headers['Content-Type']).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      expect(page.response_headers['Content-Disposition']).to include('users_export_')
    end
  end
  
  describe 'Importación de usuarios' do
    let(:csv_file) { Rails.root.join('spec', 'fixtures', 'files', 'users_import.csv') }
    let(:invalid_csv_file) { Rails.root.join('spec', 'fixtures', 'files', 'invalid_users_import.csv') }
    
    it 'permite importar usuarios desde un archivo CSV' do
      click_link 'Importar Usuarios'
      
      attach_file('Archivo CSV', csv_file)
      click_button 'Importar'
      
      expect(page).to have_content('Usuarios importados correctamente')
      expect(User.count).to be > 4 # 4 usuarios iniciales + los importados
    end
    
    it 'muestra errores de importación' do
      click_link 'Importar Usuarios'
      
      attach_file('Archivo CSV', invalid_csv_file)
      click_button 'Importar'
      
      expect(page).to have_content('Error al importar usuarios')
      expect(page).to have_content('no puede estar en blanco')
    end
  end
  
  describe 'Filtros avanzados' do
    let!(:recent_user) { create(:user, created_at: 1.day.ago) }
    let!(:old_user) { create(:user, created_at: 1.month.ago) }
    
    before do
      click_link 'Filtros Avanzados'
    end
    
    it 'permite filtrar por rango de fechas' do
      fill_in 'Fecha inicio', with: 1.week.ago.strftime('%Y-%m-%d')
      fill_in 'Fecha fin', with: Date.today.strftime('%Y-%m-%d')
      click_button 'Aplicar Filtros'
      
      expect(page).to have_content(recent_user.email)
      expect(page).not_to have_content(old_user.email)
    end
    
    it 'permite filtrar por rol' do
      select 'Administrador', from: 'Rol'
      click_button 'Aplicar Filtros'
      
      expect(page).to have_content(admin.email)
      expect(page).not_to have_content(user.email)
    end
    
    it 'permite restablecer los filtros' do
      select 'Administrador', from: 'Rol'
      click_button 'Aplicar Filtros'
      
      expect(page).to have_content(admin.email)
      
      click_link 'Restablecer Filtros'
      
      expect(page).to have_content(user.email)
      expect(page).to have_content(admin.email)
    end
  end
  
  describe 'Estadísticas' do
    before do
      click_link 'Estadísticas'
    end
    
    it 'muestra estadísticas de usuarios' do
      expect(page).to have_content('Total de Usuarios')
      expect(page).to have_content('Usuarios Activos')
      expect(page).to have_content('Usuarios Inactivos')
      expect(page).to have_content('Administradores')
    end
    
    it 'muestra un gráfico de registro de usuarios' do
      expect(page).to have_selector('#users-registration-chart')
    end
  end
  
  describe 'Acceso no autorizado' do
    before do
      logout(:user)
      login_as(user, scope: :user) # Usuario normal, no administrador
      visit admin_users_path
    end
    
    it 'redirige a la página de inicio con un mensaje de error' do
      expect(page).to have_content('No estás autorizado para realizar esta acción')
      expect(current_path).to eq(root_path)
    end
  end
end
