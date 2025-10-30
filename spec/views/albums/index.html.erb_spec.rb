require 'rails_helper'

RSpec.describe "albums/index.html.erb", type: :view do
  it 'shows welcome when not signed in' do
    # define helper method on the view instance
    view.singleton_class.send(:define_method, :current_user) { nil }
    render
    expect(rendered).to include('Welcome to Aura')
  end

  it 'shows spotify search when user connected' do
    user = build_stubbed(:user)
    allow(user).to receive(:spotify_connected?).and_return(true)
    view.singleton_class.send(:define_method, :current_user) { user }
    render
    expect(rendered).to include('Search Spotify')
  end
end
