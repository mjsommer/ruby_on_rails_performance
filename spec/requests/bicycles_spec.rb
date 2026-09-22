require 'rails_helper'

RSpec.describe "Bicycles", type: :request do
  let(:valid_attributes) do
    { brand: "Trek", model: "Domane SL5", usage_type: "road", color: "Matte Black", wheels: 2 }
  end

  let(:invalid_attributes) do
    { brand: "", model: "Domane SL5", usage_type: "mountain", color: "Matte Black", wheels: 0 }
  end

  describe "GET /bicycles" do
    it "lists all bicycles" do
      bicycle = create(:bicycle)

      get bicycles_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(bicycle.brand)
    end
  end

  describe "GET /bicycles/:id" do
    it "shows the bicycle" do
      bicycle = create(:bicycle)

      get bicycle_path(bicycle)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(bicycle.model)
    end
  end

  describe "GET /bicycles/new" do
    it "renders the new bicycle form" do
      get new_bicycle_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /bicycles" do
    context "with valid parameters" do
      it "creates a new Bicycle" do
        expect {
          post bicycles_path, params: { bicycle: valid_attributes }
        }.to change(Bicycle, :count).by(1)

        expect(response).to redirect_to(bicycle_path(Bicycle.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new Bicycle" do
        expect {
          post bicycles_path, params: { bicycle: invalid_attributes }
        }.not_to change(Bicycle, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /bicycles/:id/edit" do
    it "renders the edit bicycle form" do
      bicycle = create(:bicycle)

      get edit_bicycle_path(bicycle)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /bicycles/:id" do
    context "with valid parameters" do
      let(:new_attributes) { { color: "Red" } }

      it "updates the requested bicycle" do
        bicycle = create(:bicycle)

        patch bicycle_path(bicycle), params: { bicycle: new_attributes }
        bicycle.reload

        expect(bicycle.color).to eq("Red")
        expect(response).to redirect_to(bicycle_path(bicycle))
      end
    end

    context "with invalid parameters" do
      it "does not update the bicycle" do
        bicycle = create(:bicycle)

        patch bicycle_path(bicycle), params: { bicycle: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_content)
        expect(bicycle.reload.brand).not_to eq("")
      end
    end
  end

  describe "DELETE /bicycles/:id" do
    it "destroys the requested bicycle" do
      bicycle = create(:bicycle)

      expect {
        delete bicycle_path(bicycle)
      }.to change(Bicycle, :count).by(-1)

      expect(response).to redirect_to(bicycles_path)
    end
  end
end
