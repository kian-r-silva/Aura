require "rails_helper"

RSpec.describe ReviewsController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    context "with valid params and existing album" do
      it "creates a review and redirects to the album" do
        album = create(:album)

        post :create, params: { album_id: album.id, review: { rating: 5, comment: "This is a great album!" } }

        expect(response).to redirect_to(album_path(album))
        expect(flash[:notice]).to match(/Review added/i)
        expect(album.reviews.count).to be >= 1
      end
    end

    context "with invalid params" do
        it "renders albums/show with unprocessable_entity and sets alert" do
          album = create(:album)

          post :create, params: { album_id: album.id, review: { rating: 0, comment: "short" } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash[:alert]).to match(/Unable to save review/i)

          review = controller.instance_variable_get(:@review)
          expect(review).to be_present
          expect(review.errors).not_to be_empty
        end
    end
  end
end
