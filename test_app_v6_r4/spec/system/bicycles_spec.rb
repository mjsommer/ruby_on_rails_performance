require 'rails_helper'

RSpec.describe "Bicycles", type: :system do
  before { driven_by(:rack_test) }

  it "creates a bicycle and shows it in the index" do
    visit bicycles_path

    click_link "New Bicycle"

    fill_in "Brand", with: "Cannondale"
    fill_in "Model", with: "Synapse"
    select "road", from: "Usage type"
    fill_in "Color", with: "Blue"
    fill_in "Wheels", with: 2
    click_button "Create Bicycle"

    expect(page).to have_content("Bicycle was successfully created")

    visit bicycles_path

    expect(page).to have_content("Cannondale")
    expect(page).to have_content("Synapse")
  end
end
