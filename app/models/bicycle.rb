class Bicycle < ApplicationRecord
  USAGE_TYPES = %w[road off-road].freeze

  validates :brand, presence: true
  validates :model, presence: true
  validates :color, presence: true
  validates :usage_type, presence: true, inclusion: { in: USAGE_TYPES }
  validates :wheels, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :road, -> { where(usage_type: "road") }
  scope :off_road, -> { where(usage_type: "off-road") }
end
