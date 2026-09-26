require 'rails_helper'

RSpec.describe Bicycle, type: :model do
  subject(:bicycle) { build(:bicycle) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(bicycle).to be_valid
    end

    it "requires a brand" do
      bicycle.brand = nil
      expect(bicycle).not_to be_valid
      expect(bicycle.errors[:brand]).to include("can't be blank")
    end

    it "requires a model" do
      bicycle.model = nil
      expect(bicycle).not_to be_valid
      expect(bicycle.errors[:model]).to include("can't be blank")
    end

    it "requires a color" do
      bicycle.color = nil
      expect(bicycle).not_to be_valid
      expect(bicycle.errors[:color]).to include("can't be blank")
    end

    it "requires usage_type to be road or off-road" do
      bicycle.usage_type = "mountain"
      expect(bicycle).not_to be_valid
      expect(bicycle.errors[:usage_type]).to include("is not included in the list")
    end

    it "accepts off-road as a valid usage_type" do
      bicycle.usage_type = "off-road"
      expect(bicycle).to be_valid
    end

    it "requires wheels to be present" do
      bicycle.wheels = nil
      expect(bicycle).not_to be_valid
      expect(bicycle.errors[:wheels]).to include("can't be blank")
    end

    it "requires wheels to be a positive integer" do
      bicycle.wheels = 0
      expect(bicycle).not_to be_valid
      expect(bicycle.errors[:wheels]).to include("must be greater than 0")
    end

    it "rejects non-integer wheels" do
      bicycle.wheels = 2.5
      expect(bicycle).not_to be_valid
      expect(bicycle.errors[:wheels]).to include("must be an integer")
    end
  end

  describe "scopes" do
    let!(:road_bike) { create(:bicycle, usage_type: "road") }
    let!(:off_road_bike) { create(:bicycle, :off_road) }

    describe ".road" do
      it "returns only road bicycles" do
        expect(Bicycle.road).to contain_exactly(road_bike)
      end
    end

    describe ".off_road" do
      it "returns only off-road bicycles" do
        expect(Bicycle.off_road).to contain_exactly(off_road_bike)
      end
    end
  end
end
