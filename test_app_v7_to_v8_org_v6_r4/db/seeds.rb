# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Bicycle.destroy_all

Bicycle.create!([
  { brand: "Trek", model: "Domane SL5", usage_type: "road", color: "Matte Black", wheels: 2 },
  { brand: "Specialized", model: "Tarmac SL7", usage_type: "road", color: "Red", wheels: 2 },
  { brand: "Cannondale", model: "Synapse", usage_type: "road", color: "Blue", wheels: 2 },
  { brand: "Trek", model: "Fuel EX", usage_type: "off-road", color: "Green", wheels: 2 },
  { brand: "Specialized", model: "Stumpjumper", usage_type: "off-road", color: "Orange", wheels: 2 },
  { brand: "Santa Cruz", model: "Hightower", usage_type: "off-road", color: "Grey", wheels: 2 },
  { brand: "Giant", model: "Trance X", usage_type: "off-road", color: "Yellow", wheels: 2 },
  { brand: "Nimbus", model: "Nightrider", usage_type: "off-road", color: "Black", wheels: 1 },
  { brand: "Santana", model: "Vision", usage_type: "road", color: "Silver", wheels: 2 },
])
