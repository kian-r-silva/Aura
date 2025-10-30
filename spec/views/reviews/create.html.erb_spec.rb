require 'rails_helper'

RSpec.describe "reviews/create.html.erb", type: :view do
  it 'renders placeholder reviews create view' do
    render
    expect(rendered).to include('Find me in app/views/reviews/create.html.erb')
  end
end
