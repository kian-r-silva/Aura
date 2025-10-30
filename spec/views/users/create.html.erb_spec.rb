require 'rails_helper'

RSpec.describe "users/create.html.erb", type: :view do
  it 'renders placeholder users create view' do
    render
    expect(rendered).to include('Users#create')
  end
end
