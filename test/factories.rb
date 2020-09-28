FactoryBot.define do

  factory :account do
    name            { Faker::Name.name }
  end

  factory :email_address do
    address   { Faker::Internet.email }
  end
  
  factory :photo do
    format          { ['jpg', 'png', 'tiff'].sample }
  end
  
  factory :property do
    name            { Faker::Lorem.words(Kernel.rand(1..4)).join(' ') }
    description     { Faker::Lorem.sentence }
    constructed     { Kernel.rand(1800..(Time.now.year - 2)) }
    size            { Kernel.rand(1000..10000000).to_f / 100 }
    active          { false }#[true, false].sample }
  end
  
  factory :region do
    name            { Faker::Name.name }
  end

  factory :comment do
    title { Faker::Lorem.words }
    body  { Faker::Lorem.sentence }
  end
  
  factory :unobserved_model do
    body  { Faker::Lorem.sentence }
  end
  
end