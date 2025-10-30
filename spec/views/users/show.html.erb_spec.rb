require 'rails_helper'

RSpec.describe "users/show.html.erb", type: :view do
  it 'renders user profile' do
    user = create(:user, name: 'Profile User')
    assign(:user, user)
    render
    expect(rendered).to include('Profile User')
  end
end
