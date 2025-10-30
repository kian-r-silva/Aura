require 'rails_helper'

RSpec.describe "Reviews", type: :request do
  let(:user) { create(:user) }
  let(:album) { create(:album) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a review and redirects to album" do
        params = { 
          review: { rating: 4, comment: 'Great album with amazing songs!' }, 
          album_id: album.id 
        }
        
        expect {
          post album_reviews_path(album), params: params
        }.to change(Review, :count).by(1)
        
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(album_path(album))
        follow_redirect!
        expect(response.body).to include('Review added')
      end

      it "creates a review with album_title and artists" do
        params = { 
          review: { rating: 5, comment: 'Fantastic album!' },
          album_title: 'Dark Side of the Moon',
          artists: 'Pink Floyd'
        }
        
        expect {
          post reviews_path, params: params
        }.to change(Review, :count).by(1)
        
        expect(response).to have_http_status(:redirect)
      end
    end

    context "with invalid parameters" do
      it "does not create review with invalid rating" do
        params = { 
          review: { rating: 10, comment: 'Too high rating!' }, 
          album_id: album.id 
        }
        
        expect {
          post album_reviews_path(album), params: params
        }.not_to change(Review, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Unable to save review')
      end

      it "does not create review with short comment" do
        params = { 
          review: { rating: 4, comment: 'Short' }, 
          album_id: album.id 
        }
        
        expect {
          post album_reviews_path(album), params: params
        }.not_to change(Review, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create review without comment" do
        params = { 
          review: { rating: 4, comment: '' }, 
          album_id: album.id 
        }
        
        expect {
          post album_reviews_path(album), params: params
        }.not_to change(Review, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create review without rating" do
        params = { 
          review: { rating: nil, comment: 'This is a comment' }, 
          album_id: album.id 
        }
        
        expect {
          post album_reviews_path(album), params: params
        }.not_to change(Review, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
