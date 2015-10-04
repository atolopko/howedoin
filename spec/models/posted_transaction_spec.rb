require 'spec_helper'

describe PostedTransaction do

  describe "#find_matching_txn" do
    let(:account) { FactoryGirl.create(:account, :asset) }
    let(:posted_txn) { FactoryGirl.build(:posted_transaction,
                                         account: account,
                                         amount: -5.11,
                                         sale_date: Date.new(2014, 1, 1),
                                         txn: nil) }

    def create_matching_txn(attrs = {})
      FactoryGirl.create(:txn,
                         from_account: attrs[:account] || account,
                         amount: attrs[:amount] || -5.11,
                         date: attrs[:date] || Date.new(2014, 1, 1))
    end

    def create_non_matching_txns
      create_matching_txn(amount: -5.12)
      create_matching_txn(date: Date.new(2014, 1, 2))
      create_matching_txn(account: FactoryGirl.create(:account, :asset))
    end

    it "returns nil if it has a pre-associated txn" do
      txn = create_matching_txn
      posted_txn.txn = txn
      posted_txn.save!
      expect(posted_txn.find_matching_txn).to be_nil
    end

    it "returns a matching txn, if one exists" do
      matching_txn = create_matching_txn
      create_non_matching_txns
      expect(posted_txn.find_matching_txn).to eq matching_txn
    end

    it "raises exception if multiple txns match" do
      matching_txns = Array.new(2).map { create_matching_txn }
      expect { posted_txn.find_matching_txn }.
        to raise_error PostedTransaction::MultipleMatchingTxns, /#{matching_txns[0].id}, #{matching_txns[1].id}/
    end

    it "returns nil if no matching txns" do
      non_matching_amount_txn = create_matching_txn(amount: -5.12)
      non_matching_date_txn = create_matching_txn(date: Date.new(2014, 1, 2))
      non_matching_account_txn = create_matching_txn(account: FactoryGirl.create(:account, :asset))
      expect(posted_txn.find_matching_txn).to be_nil
    end
  end

  describe "non-unique record" do
    let!(:persisted) { FactoryGirl.create(:posted_transaction,
                                          post_date: Date.current,
                                          amount: BigDecimal.new('1.00'),
                                          reference_identifier: 'reference_identifier',
                                          type_identifier: 'type_identifier',
                                          category: 'category',
                                          memo: 'memo', 
                                          person: 'person') } 
    let(:unpersisted) { FactoryGirl.build(:posted_transaction,
                                         reference_identifier: 'reference_identifier') }

    it "is invalid" do
      expect(unpersisted).to be_invalid
    end
  end

end
