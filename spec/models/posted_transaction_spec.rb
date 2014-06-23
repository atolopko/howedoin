require 'spec_helper'

describe PostedTransaction do

  describe "#matching" do
    let(:account) { FactoryGirl.create(:account) }

    def new_posted_txn
      FactoryGirl.build(:posted_transaction,
                        account: account,
                        sale_date: Date.new(2014, 1, 1),
                        post_date: Date.new(2014, 1, 2),
                        amount: BigDecimal("1.15"),
                        type_identifier: "1",
                        category: "Groceries",
                        memo: "Half Foods",
                        person: "Chuck Jones")
    end

    it "finds matching when account and all data attributes match" do
      saved_posted_txn = new_posted_txn
      saved_posted_txn.save!
      expect(new_posted_txn.matching).to eq [saved_posted_txn]
    end

    it "does not find matching when all data attributes match but account is different" do
      saved_posted_txn = new_posted_txn
      saved_posted_txn.account = FactoryGirl.create(:account)
      saved_posted_txn.save!
      expect(new_posted_txn.matching).to be_empty
    end

    it "does not find matching when account matches but some data attributes do not match" do
      saved_posted_txn = new_posted_txn
      saved_posted_txn.update_attributes!(amount: BigDecimal("1.16"))
      expect(new_posted_txn.matching).to be_empty
    end

    it "does not allow itself to be called if already persisted" do
      saved_posted_txn = new_posted_txn
      saved_posted_txn.save!
      expect { saved_posted_txn.matching }.to raise_error /can only be called if not persisted/
    end
  end

  describe "#find_matching_txn" do
    it "returns the pre-associated txn, if it exists" do
      posted_txn = FactoryGirl.create(:posted_transaction)
      expect(posted_txn.find_matching_txn).to eq posted_txn.txn
    end

    it "returns a matching txn, if one exists" do
      account = FactoryGirl.create(:account, :asset)
      posted_txn = FactoryGirl.build(:posted_transaction, account: account, amount: -5.11, sale_date: Date.new(2014, 1, 1), txn: nil)
      matching_txn = FactoryGirl.create(:txn, from_account: account, amount: -5.11, date: Date.new(2014, 1, 1))
      non_matching_amount_txn = FactoryGirl.create(:txn, from_account: account, amount: -5.12, date: Date.new(2014, 1, 1))
      non_matching_date_txn = FactoryGirl.create(:txn, from_account: account, amount: -5.11, date: Date.new(2014, 1, 2))
      non_matching_account_txn = FactoryGirl.create(:txn, from_account: account, amount: -5.11, date: Date.new(2014, 1, 2))
      expect(posted_txn.find_matching_txn).to eq matching_txn
    end

    it "raises exception if multiple txns match" do
      account = FactoryGirl.create(:account, :asset)
      posted_txn = FactoryGirl.build(:posted_transaction, account: account, amount: -5.11, sale_date: Date.new(2014, 1, 1), txn: nil)
      matching_txn1 = FactoryGirl.create(:txn, from_account: account, amount: -5.11, date: Date.new(2014, 1, 1))
      matching_txn2 = FactoryGirl.create(:txn, from_account: account, amount: -5.11, date: Date.new(2014, 1, 1))
      expect { posted_txn.find_matching_txn }.to raise_error PostedTransaction::MultipleMatchingTxns, /#{matching_txn1.id}, #{matching_txn2.id}/
    end

    it "returns nil if no matching txns" do
      account = FactoryGirl.create(:account, :asset)
      posted_txn = FactoryGirl.build(:posted_transaction, account: account, amount: -5.11, sale_date: Date.new(2014, 1, 1), txn: nil)
      non_matching_amount_txn = FactoryGirl.create(:txn, from_account: account, amount: -5.12, date: Date.new(2014, 1, 1))
      non_matching_date_txn = FactoryGirl.create(:txn, from_account: account, amount: -5.11, date: Date.new(2014, 1, 2))
      non_matching_account_txn = FactoryGirl.create(:txn, from_account: account, amount: -5.11, date: Date.new(2014, 1, 2))
      expect(posted_txn.find_matching_txn).to be_nil
    end
  end

  describe "non-unique record" do
    let(:persisted) { FactoryGirl.create(:posted_transaction,
                                         post_date: Date.current,
                                         amount: BigDecimal.new('1.00'),
                                         reference_identifier: 'reference_identifier',
                                         type_identifier: 'type_identifier',
                                         category: 'category',
                                         memo: 'memo', 
                                         person: 'person') } 
    let(:unpersisted) { FactoryGirl.build(:posted_transaction,
                                          persisted.attributes.delete_if { |k| k == 'id' }) }

    it "is invalid" do
      expect(unpersisted).to be_invalid
    end

    it "is invalid" do
      unpersisted.valid?
      expect(unpersisted.errors.full_messages).to include "Data non-unique"
    end
  end

end
