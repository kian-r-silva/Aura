require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  render_views

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a user and redirects to root' do
        expect {
          post :create, params: { user: { name: 'Test', username: 'test1', email: 't@example.com', password: 'password', password_confirmation: 'password' } }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
      end
    end

    context 'with invalid params' do
      it 'renders new with unprocessable_entity' do
        post :create, params: { user: { name: '', username: '', email: 'bad', password: '', password_confirmation: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('error') if response.body.present?
      end
    end
  end
end
