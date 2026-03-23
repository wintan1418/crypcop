FactoryBot.define do
  factory :trust_vote do
    user
    token
    vote { :trust }

    trait :distrust do
      vote { :distrust }
    end
  end
end
