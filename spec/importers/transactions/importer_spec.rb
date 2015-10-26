require 'spec_helper'

module Transactions
  describe Importer do

    let(:pt) { create(:posted_transaction, amount: BigDecimal(2), memo: "memo") }
    let(:importer) { Importer.new(pt) }
    let!(:txn_importer_factory) { create(:txn_importer_factory,
                                         from_account: pt.account,
                                         memo_regexp: 'memo') }
    
    shared_examples "posted transaction processed" do
      it "creates a new Txn" do
        expect(importer.txn).to be_present
      end

      it "persists the new Txn" do
        expect(importer.txn).to be_persisted
      end

      it "links new Txn to PostedTransaction" do
        expect(pt.reload.txn).to eq importer.txn
      end

      it "records the transaction import factory used" do
        expect(pt.reload.txn_importer_factory).to eq txn_importer_factory
      end
    end

    describe ".import_all" do
      pending
    end

    describe "PostedTransaction not yet imported" do
      before do
        importer.import
      end

      it_behaves_like "posted transaction processed"

      describe "withdrawal from asset type account" do
        let(:account) { create(:account, :asset) }
        let(:pt) { create(:posted_transaction,
                          account: account,
                          amount: -BigDecimal(2),
                          memo: "memo") }
        let!(:txn_importer_factory) { create(:txn_importer_factory,
                                             from_account: pt.account,
                                             to_account: create(:account, :expense),
                                             memo_regexp: 'memo') }

        it "debits asset account and credits 'to' account" do
          expect(pt.reload.txn.amount).to eq -2
        end
      end

      describe "deposit to asset type account" do
        let(:account) { create(:account, :asset) }
        let(:pt) { create(:posted_transaction,
                          account: account,
                          amount: BigDecimal(2),
                          memo: "memo") }
        let!(:txn_importer_factory) { create(:txn_importer_factory,
                                             from_account: pt.account,
                                             to_account: create(:account, :income),
                                             memo_regexp: 'memo') }

        it "debits asset account and credits 'to' account" do
          expect(pt.reload.txn.amount).to eq 2
        end
      end

      describe "withdrawal from liability type account" do
        let(:account) { create(:account, :liability) }
        let(:pt) { create(:posted_transaction,
                          account: account,
                          amount: -BigDecimal(2),
                          memo: "memo") }
        let!(:txn_importer_factory) { create(:txn_importer_factory,
                                             from_account: pt.account,
                                             to_account: create(:account, :expense),
                                             memo_regexp: 'memo') }

        it "debits liability account and credits 'to' account" do
          expect(pt.reload.txn.amount).to eq -2
        end
      end

      describe "deposit to liability type account" do
        let(:account) { create(:account, :liability) }
        let(:pt) { create(:posted_transaction,
                          account: account,
                          amount: BigDecimal(2),
                          memo: "memo") }
        let!(:txn_importer_factory) { create(:txn_importer_factory,
                                             from_account: pt.account,
                                             to_account: create(:account, :expense),
                                             memo_regexp: 'memo') }

        it "debits asset account and credits 'to' account" do
          expect(pt.reload.txn.amount).to eq 2
        end
      end

      describe "only sale date exists on posted transaction" do
        let(:pt) { create(:posted_transaction,
                          amount: BigDecimal(2), memo: "memo",
                          sale_date: Date.current - 1.day, post_date: nil) }

        it "creates Txn with sale date" do
          expect(importer.txn.date).to eq pt.sale_date
        end
      end
      
      describe "sale and post date exist on posted transaction" do
        let(:pt) { create(:posted_transaction,
                          amount: BigDecimal(2), memo: "memo",
                          sale_date: Date.current - 1.day, post_date: Date.current) }

        it "creates Txn with sale date" do
          expect(importer.txn.date).to eq pt.sale_date
        end
      end
      
      describe "only post date exists on posted transaction" do
        let(:pt) { create(:posted_transaction,
                          amount: BigDecimal(2), memo: "memo",
                          sale_date: nil, post_date: Date.current) }

        it "creates Txn with post date" do
          expect(importer.txn.date).to eq pt.post_date
        end
      end
    end

    describe "matching, unlinked Txn exists" do
      let!(:txn) { create(:txn,
                          from_account: pt.account,
                          amount: pt.amount,
                          date: pt.sale_date) }
      
      it "links PostedTransaction to existing Txn" do
        expect { importer.import }.to change { pt.reload.txn }.from(nil).to(txn)
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

    describe "amount range specified" do
      let!(:txn_importer_factory) { create(:txn_importer_factory,
                                           min_amount: BigDecimal(1),
                                           max_amount: BigDecimal(3),
                                           from_account: pt.account,
                                           memo_regexp: 'memo') }

      before do
        importer.import
      end

      describe "amount out of range" do
        let(:pt) { create(:posted_transaction,
                          memo: "memo",
                          amount: BigDecimal.new('4.0')) }
        
        it_behaves_like "posted transaction not processed"
      end

      describe "amount in range" do
        let(:pt) { create(:posted_transaction,
                          memo: "memo",
                          amount: BigDecimal.new('2.0')) }
        
        it_behaves_like "posted transaction processed"
      end
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
