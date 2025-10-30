require 'rails_helper'

RSpec.describe "sessions/destroy.html.erb", type: :view do
  it 'renders placeholder session destroy view' do
    render
    expect(rendered).to include('Sessions#destroy')
  end
end
