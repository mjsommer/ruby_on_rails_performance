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

  it "shows validation errors and does not create a bicycle with blank fields" do
    visit new_bicycle_path

    click_button "Create Bicycle"

    expect(page).to have_content("prohibited this bicycle from being saved")
    expect(page).to have_content("Brand can't be blank")
    expect(page).to have_content("New Bicycle") # redisplays the form rather than redirecting
    expect(Bicycle.count).to eq(0)
  end

  it "edits an existing bicycle" do
    bicycle = create(:bicycle, brand: "Trek", color: "Matte Black")

    visit bicycles_path
    click_link "Edit"

    fill_in "Color", with: "Red"
    click_button "Update Bicycle"

    expect(page).to have_content("Bicycle was successfully updated")
    expect(page).to have_content("Red")

    visit bicycles_path
    expect(page).to have_content("Trek")
  end

  it "deletes a bicycle" do
    create(:bicycle, brand: "Trek", model: "Domane SL5")

    visit bicycles_path
    click_link "Delete"

    expect(page).to have_content("Bicycle was successfully destroyed")
    expect(page).not_to have_content("Domane SL5")
  end
end
