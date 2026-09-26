class CreateBicycles < ActiveRecord::Migration[6.1]
  def change
    create_table :bicycles do |t|
      t.string :brand
      t.string :model
      t.string :usage_type
      t.string :color
      t.integer :wheels

      t.timestamps
    end
  end
end
