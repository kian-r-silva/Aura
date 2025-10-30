require 'rails_helper'

RSpec.describe "albums/new.html.erb", type: :view do
  it 'renders the new album form' do
    assign(:album, Album.new)
    render
    expect(rendered).to include('Add a New Album')
    expect(rendered).to include('Album Title')
  end
end
