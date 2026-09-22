class AddConstraintsToBicycles < ActiveRecord::Migration[6.1]
  def change
    change_column_default :bicycles, :wheels, from: nil, to: 2

    add_check_constraint :bicycles,
                          "usage_type IN ('road', 'off-road')",
                          name: "usage_type_check"
  end
end
