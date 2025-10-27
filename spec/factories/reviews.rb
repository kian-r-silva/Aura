FactoryBot.define do
  factory :review do
    rating { 1 }
    comment { "MyText" }
    user { nil }
    album { nil }
  end
end
