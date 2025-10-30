require 'rails_helper'

RSpec.describe "albums/create.html.erb", type: :view do
  it 'renders placeholder create view' do
    render
    expect(rendered).to include('Find me in app/views/users/create.html.erb').or include('Users#create')
  end
end
