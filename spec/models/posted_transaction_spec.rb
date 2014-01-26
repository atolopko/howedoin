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
      expect(new_posted_txn.matching).to eq saved_posted_txn
    end

    it "does not find matching when all data attributes match but account is different" do
      saved_posted_txn = new_posted_txn
      saved_posted_txn.save!
      expect(new_posted_txn.matching).to eq saved_posted_txn
    end

    it "does not find matching when account matches but some data attributes do not match" do
      saved_posted_txn = new_posted_txn
      saved_posted_txn.save!
      expect(new_posted_txn.matching).to eq saved_posted_txn
    end
  end

end
