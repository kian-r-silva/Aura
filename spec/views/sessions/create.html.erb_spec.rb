require 'rails_helper'

RSpec.describe "sessions/create.html.erb", type: :view do
  it 'renders placeholder session create view' do
    render
    expect(rendered).to include('Sessions#create').or include('Find me in app/views/sessions/create.html.erb')
  end
end
