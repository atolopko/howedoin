FactoryGirl.define do

  factory :account do
    ignore do
      acct_type_val 'asset'
    end
    acct_type { acct_type_val }
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
    ignore do
      amount -1.00
      from_account { FactoryGirl.create(:account, :asset) }
      to_account { FactoryGirl.create(:account, :expense) }
    end
    date Date.today
    payee
    after(:create) do |txn, evaluator|
      entries = [FactoryGirl.create(:entry, 
                                    txn: txn,
                                    account: evaluator.from_account, 
                                    amount: evaluator.amount),
                 FactoryGirl.create(:entry, 
                                    txn: txn,
                                    account: evaluator.to_account,
                                    amount: -evaluator.amount)]
    end
  end

  factory :statement do
    account
    sequence(:stmt_date) { |n| Date.current + n }
    balance 100.0
  end

  factory :posted_transaction do
    account
    # TODO: statement should have same account as posted_transaction
    statement
    # TODO: txn entry should have same asset account as posted_transaction
    txn
    sequence(:sale_date) { |n| Date.current + n }
    sequence(:amount, 100) { |n| BigDecimal.new(n, 2) }
  end
end
