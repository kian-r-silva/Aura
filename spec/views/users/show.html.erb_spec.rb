require 'rails_helper'

RSpec.describe "users/show.html.erb", type: :view do
  it 'renders user profile' do
    user = create(:user, name: 'Profile User')
    assign(:user, user)
    render
    expect(rendered).to include('Profile User')
  end

  it 'shows Last.fm top artists when connected' do
    user = create(:user, name: 'LF User')
    user.update!(lastfm_connected: true)
    assign(:user, user)
    analytics = AnalyticsService.new(user)
    allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
      { name: 'Karma Police', artists: 'Radiohead', album: '', image: nil },
      { name: 'Paranoid Android', artists: 'Radiohead', album: '', image: nil }
    ])
    assign(:analytics, analytics)

    render
    expect(rendered).to include('Radiohead')
  end
end
