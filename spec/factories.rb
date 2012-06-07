FactoryGirl.define do    
  sequence :rand_name do |n|
    "foo#{(n + (n+rand)).to_s[2..6]}"
  end
  
  factory :basket do
    name "MyString"
  end

  factory :fruit_basket do
    fruit
    basket
  end

  factory :fruit do
    name "MyString"
    region
  end

  factory :region do
    name "MyString"
  end

  factory :type do |f|
    f.sequence(:name) {FactoryGirl.generate(:rand_name)}
  end
end