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
        importer.import
        expect(importer.txn).to be_present
      end

      it "persists the new Txn" do
        importer.import
        expect(importer.txn).to be_persisted
      end

      it "links new Txn to PostedTransaction" do
        importer.import
        expect(pt.reload.txn).to eq importer.txn
      end

      it "links Txn entries to BankStatement" do
        importer.import
        expect(pt.reload.txn.entries.where(acct_id: pt.account.acct_id).pluck(:stmt_id)).
          to eq [pt.statement.stmt_id]
      end

      it "records the transaction import factory used" do
        importer.import
        expect(pt.reload.txn_importer_factory).to eq txn_importer_factory
      end

      it "returns :created" do
        expect(importer.import).to eq :created
      end
    end

    shared_examples "posted transaction not processed" do |return_val|
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

      it "returns #{return_val}" do
        expect(importer.import).to eq return_val
      end
    end

    describe ".import_all" do
      it "processes all unimported posted transactions" do
        skip
      end

      it "processes only posted transactions that match the specified factory, if factory specified" do
        skip
      end

      it "processes only single statement, if statement specified" do
        skip
      end
    end

    describe "PostedTransaction not yet imported" do
      it_behaves_like "posted transaction processed"
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

      it "returns :linked_to_existing" do
        expect(importer.import).to eq :linked_to_existing
      end
    end

    describe "multiple matching, unlinked Txns exist" do
      let!(:txn) { create(:txn,
                          from_account: pt.account,
                          amount: pt.amount,
                          date: pt.sale_date) }
      let!(:dup_txn) { create(:txn,
                              from_account: pt.account,
                              amount: pt.amount,
                              date: pt.sale_date) }
      
      it_behaves_like "posted transaction not processed", :matches_multiple_existing
    end

    describe "PostedTransaction is already linked to a Txn" do
      let!(:pt) { create(:posted_transaction,
                         txn: create(:txn)) }

      it_behaves_like "posted transaction not processed", :previously_imported
    end

    describe "no matching factory due to memo mismatch" do
      let!(:txn_importer_factory) { create(:txn_importer_factory,
                                           from_account: pt.account,
                                           memo_regexp: 'more_specific_memo') }

      it_behaves_like "posted transaction not processed", :not_imported
    end

    describe "amount range specified" do
      let!(:txn_importer_factory) { create(:txn_importer_factory,
                                           min_amount: BigDecimal(1),
                                           max_amount: BigDecimal(3),
                                           from_account: pt.account,
                                           memo_regexp: 'memo') }

      describe "amount out of range" do
        let(:pt) { create(:posted_transaction,
                          memo: "memo",
                          amount: BigDecimal.new('4.0')) }
        
        it_behaves_like "posted transaction not processed", :not_imported
      end

      describe "amount in range" do
        let(:pt) { create(:posted_transaction,
                          memo: "memo",
                          amount: BigDecimal.new('2.0')) }
        
        it_behaves_like "posted transaction processed"
      end
    end

    describe "date range specified" do
      let!(:txn_importer_factory) { create(:txn_importer_factory,
                                           min_date: '2016-01-01',
                                           max_date: '2016-01-03',
                                           from_account: pt.account,
                                           memo_regexp: 'memo') }

      ['2015-12-31', '2016-01-03'].each do |date|
        describe "post date out of range" do
          let(:pt) { create(:posted_transaction,
                            memo: "memo",
                            post_date: Date.parse(date)) }
          
          it_behaves_like "posted transaction not processed", :not_imported
        end

        describe "sale date out of range" do
          let(:pt) { create(:posted_transaction,
                            memo: "memo",
                            sale_date: Date.parse(date)) }
          
          it_behaves_like "posted transaction not processed", :not_imported
        end
      end

      ['2016-01-01', '2016-01-02'].each do |date|
        describe "post date in range" do
          let(:pt) { create(:posted_transaction,
                            memo: "memo",
                            post_date: Date.parse(date)) }
          
          it_behaves_like "posted transaction processed"
        end
        
        
        describe "sale date in range" do
          let(:pt) { create(:posted_transaction,
                            memo: "memo",
                            sale_date: Date.parse(date)) }
        
          it_behaves_like "posted transaction processed"
        end
      end
    end

    describe "ambiguous matching factory" do
      before do
        create(:txn_importer_factory,
               from_account: pt.account,
               memo_regexp: 'emo')
      end

      it_behaves_like "posted transaction not processed", :not_imported
    end

    describe "reusing Importer object that has already created a txn" do
      before do
        importer.import
      end

      it "does not create a new Txn" do
        expect { importer.import }.not_to change { Txn.count }
      end

      it "does not change link" do
        expect { importer.import }.not_to change { pt.txn }
      end

      it "returns :redundant_call" do
        expect(importer.import).to eq :redundant_call
      end
    end

    describe "created Txn" do
      before do
        importer.import
      end

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

      # Test credit card account that reports statement debits as
      # positive values
      describe "account negated statement amounts" do
        describe "withdrawal from liability type account" do
          let(:account) { create(:account, :asset,
                                 stmt_amounts_negated: true) }
          let(:pt) { create(:posted_transaction,
                            account: account,
                            amount: BigDecimal(2),
                            memo: "memo") }
          let!(:txn_importer_factory) { create(:txn_importer_factory,
                                               from_account: pt.account,
                                               to_account: create(:account, :expense),
                                               memo_regexp: 'memo') }
          
          it "debits liability account and credits 'to' account" do
            expect(pt.reload.txn.amount).to eq -2
          end
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

      describe "entry creation" do
        it "sets statement of 'from' entry" do
          expect(importer.txn.entries.first.statement).to eq pt.statement
        end

        # TODO: verify other entry attributes set correctly
      end
      
    end
    
  end
end
