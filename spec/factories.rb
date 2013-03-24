FactoryGirl.define do

  factory :account do
    ignore do
      acct_type_val 'asset'
    end
    acct_type { acct_type_val }
    entered { Time.zone.now }
    sequence(:name) { |i| "#{acct_type_val}#{i}" }

    trait :asset do
      acct_type_val 'asset'
    end

    trait :expense do
      acct_type_val 'expense'
    end

    trait :income do
      acct_type_val 'income'
    end

    trait :liability do
      acct_type_val 'liability'
    end
  end

  factory :payee do
    sequence(:name) { |i| "payee#{i}" }
    entered { Time.zone.now }
  end

  factory :user do
    sequence(:fullname) { |i| "user#{i}" }
    sequence(:nickname) { |i| "n#{i}" }
  end

  factory :entry do
    txn
    user
    account
    amount 1.00
  end

  factory :txn do
    date Date.today
    payee
    after(:create) do |txn, evaluator|
      entries = [FactoryGirl.create(:entry, 
                                    txn: txn,
                                    account: FactoryGirl.create(:account, :asset), 
                                    amount: -1.00),
                 FactoryGirl.create(:entry, 
                                    txn: txn,
                                    account: FactoryGirl.create(:account, :expense), 
                                    amount: 1.00)]
    end
  end


end
