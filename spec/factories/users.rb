FactoryGirl.define do
  factory :user do
    name { "Вася_#{rand(12345)}"}

    sequence(:email) { |n| "user#{n}@example.com" }

    is_admin false

    balance 0

    after(:build) { |u| u.password_confirmation = u.password = "123456" }
  end
end