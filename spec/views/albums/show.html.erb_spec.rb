require 'rails_helper'

RSpec.describe "albums/show.html.erb", type: :view do
  it 'renders album details and encourages sign in when anonymous' do
    album = create(:album, title: 'Test Album', artist: 'Test Artist')
    assign(:album, album)
    assign(:review, Review.new)
    view.singleton_class.send(:define_method, :current_user) { nil }
    render
    expect(rendered).to include('You must')
    expect(rendered).to include('Test Album')
  end
end
