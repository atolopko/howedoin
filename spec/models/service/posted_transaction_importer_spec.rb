require 'spec_helper'

module Service
  describe PostedTransactionImporter do

    let(:importer) { PostedTransactionImporter.new(records, associated_account) }
    let(:records) {
      [{ desc: "record1" },
       { desc: "record2" },
       { desc: "record3" }]
    }
    let(:input_file) { StringIO.new(posted_txns_json) }
    let(:posted_txns_json) { MultiJson.dump(records) }
    let!(:associated_account) { FactoryGirl.create(:account, name: 'account', acct_type_val: 'liability') }
    let!(:unassigned_account) { FactoryGirl.create(:account, name: 'unassigned', acct_type_val: 'expense') }
    let!(:user) { FactoryGirl.create(:user) }

    before do
      allow(importer).to receive(:populate) do |pt, r|
        # make a valid PostedTransaction
        pt.sale_date = Date.new(2014, 1, 1)
        pt.post_date = Date.new(2014, 1, 1)
        pt.memo = r[:desc]
        pt.amount = BigDecimal.new("1.00")
        pt.type_identifier = 'type'
        pt.category = 'category'
        pt.person = 'person'
      end
    end

    shared_examples "persisted posted transactions" do
      it "persists all transactions" do
        importer.import
        expect(PostedTransaction.count).to eq 3
      end

      it "calls populate template method for each record" do
        expect(importer).to receive(:populate).with(kind_of(PostedTransaction), records[0]).once.ordered
        expect(importer).to receive(:populate).with(kind_of(PostedTransaction), records[1]).once.ordered
        expect(importer).to receive(:populate).with(kind_of(PostedTransaction), records[2]).once.ordered
        importer.import
      end

      it "associates with correct account" do
        importer.import
        expect(PostedTransaction.pluck(:account_id).uniq).to eq [associated_account.id]
      end
    end

    describe "#import" do

      describe "valid posted transactions without existing transactions" do
        it_should_behave_like "persisted posted transactions"

        # it "creates associated Txn" do
        #   expect(PostedTransaction.first.txn.date).to eq Date.new(2014, 1, 17)
        # end

        # it "creates associated Txn entries" do
        #   expect(PostedTransaction.first.txn.entries[0].attributes.symbolize_keys).
        #     to include({acct_id: associated_account.id,
        #                  user_id: user.id,
        #                  amount: -0.99,
        #                  memo: 'NEW YORK TIMES DIGITAL 100001 NY',
        #                  num: 'xyz123'})
        #   expect(PostedTransaction.first.txn.entries[1].attributes.symbolize_keys).
        #     to include({acct_id: unassigned_account.id,
        #                  user_id: user.id,
        #                  amount: 0.99,
        #                  memo: nil,
        #                  num: nil})
        # end
      end

      # # describe "valid posted transactions with existing transactions" do
      # #   let!(:existing_txn) { FactoryGirl.create(:txn,
      # #                                            date: Date.new(2014, 1, 17),
      # #                                            amount: 0.99,
      # #                                            from_account: associated_account) }

      # #   before do
      # #     PostedTransactionImporter.new(posted_txns).import
      # #   end

      # #   it_should_behave_like "persisted posted transactions"

      # #   it "associates with existing Txn" do
      # #     expect(PostedTransaction.first.txn).to eq existing_txn
      # #   end
      # # end

      describe "invalid transactions" do
        before do
          # force PostedTransaction to be invalid
          allow(importer).to receive(:populate) do |pt, r|
            pt.errors.add(:base, "bad, bad, bad")
          end
        end

        it "returns false" do
          expect(importer.import).to be_false
        end

        it "does not persist any PostedTransactions" do
          importer.import
          expect(PostedTransaction.count).to eq 0
        end

        it "does not persist any Txns" do
          importer.import
          expect(Txn.count).to eq 0
        end

        it "provides errors in returned posted transactions" do
          importer.import
          expect(importer.results[1].errors.messages).to eq({amount: ["can't be blank", "is not a number"]})
        end
      end
    end

    describe ".load" do
      it "parses json and stores as hash" do
        expect(PostedTransactionImporter).to receive(:new).with(records)
        PostedTransactionImporter.load(input_file)
      end
    end

  end
end
