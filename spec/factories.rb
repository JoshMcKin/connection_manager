FactoryGirl.define do
  factory :basket do
    name "MyString"
  end
end

FactoryGirl.define do
  factory :fruit_basket do
    fruit
    basket
  end
end

FactoryGirl.define do
  factory :fruit do
    name "MyString"
    region
  end
end

FactoryGirl.define do
  factory :region do
    name "MyString"
  end
end

FactoryGirl.define do
  factory :type do
    name "MyString"
  end
end