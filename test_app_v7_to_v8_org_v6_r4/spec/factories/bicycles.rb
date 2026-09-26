FactoryBot.define do
  factory :bicycle do
    brand { "Trek" }
    model { "Domane SL5" }
    usage_type { "road" }
    color { "Matte Black" }
    wheels { 2 }

    trait :off_road do
      usage_type { "off-road" }
    end
  end
end
