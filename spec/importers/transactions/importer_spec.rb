require 'spec_helper'

module Transactions
  describe Importer do

    let(:pt) { create(:posted_transaction, amount: BigDecimal(2), memo: "memo") }
    let(:importer) { Importer.new(pt) }
    let!(:txn_importer_factory) { create(:txn_importer_factory,
                                         min_amount: BigDecimal(1),
                                         max_amount: BigDecimal(3),
                                         from_account: pt.account,
                                         memo_regexp: 'memo') }
    
    describe "PostedTransaction not yet imported" do
      before do
        importer.import
      end

      it "creates a new Txn" do
        expect(importer.txn).to be_present
      end

      it "persists the new Txn" do
        expect(importer.txn).to be_persisted
      end

      it "links new Txn to PostedTransaction" do
        expect(pt.reload.txn).to eq importer.txn
      end
    end

    describe "matching, unlinked Txn exists" do
      let!(:txn) { create(:txn,
                          from_account: pt.account,
                          amount: pt.amount,
                          date: pt.sale_date) }
      
      
      it "links PostedTransaction to existing Txn" do
        expect { importer.import }.to change { pt.txn }.from(nil).to(txn)
      end
      
      it "does not create a new Txn" do
        expect { importer.import }.not_to change { Txn.count }
      end
    end

    shared_examples "posted transaction not processed" do
      it "does not create a new Txn" do
        importer.import
        expect(importer.txn).not_to be_present
      end
      
      it "does not create a new Txn" do
        expect { importer.import }.not_to change { Txn.count }
      end

      it "does not change link" do
        expect { importer.import }.not_to change { pt.txn }
      end
    end

    describe "PostedTransaction is already linked to a Txn" do
      let!(:pt) { create(:posted_transaction,
                         txn: create(:txn)) }

      it_behaves_like "posted transaction not processed"
    end

    describe "no matching factory due to memo mismatch" do
      let!(:txn_importer_factory) { create(:txn_importer_factory,
                                           from_account: pt.account,
                                           memo_regexp: 'more_specific_memo') }
      it_behaves_like "posted transaction not processed"
    end

    describe "no matching factory due to amount mismatch" do
      let(:pt) { create(:posted_transaction,
                        memo: "memo",
                        amount: BigDecimal.new('4.0')) }

      it_behaves_like "posted transaction not processed"
    end

    describe "ambiguous matching factory" do
      before do
        create(:txn_importer_factory,
               from_account: pt.account,
               memo_regexp: 'emo')
      end

      it_behaves_like "posted transaction not processed"
    end

    describe "reusing PostedTransaction object that has already created a txn" do
      before do
        importer.import
      end

      it "does not create a new Txn" do
        expect { importer.import }.not_to change { Txn.count }
      end

      it "does not change link" do
        expect { importer.import }.not_to change { pt.txn }
      end
      
    end

  end
end
