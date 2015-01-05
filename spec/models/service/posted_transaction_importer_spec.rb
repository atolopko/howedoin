require 'spec_helper'

module Service
  describe PostedTransactionImporter do

    def build_importer(records, account)
      importer = PostedTransactionImporter.new(records, associated_account)
      # implement the abstract method
      def importer.populate(pt, r)
        # make a valid PostedTransaction
        pt.sale_date = Date.new(2014, 1, 1)
        pt.post_date = Date.new(2014, 1, 1)
        pt.memo = 'memo'
        pt.amount = r[:amount] || BigDecimal.new("1.00")
        pt.reference_identifier = r[:reference_identifier]
        pt.type_identifier = 'type'
        pt.category = 'category'
        pt.person = 'person'
      end
      importer
    end

    let(:importer) { build_importer(records, associated_account) }
    let(:records) {
      [{ reference_identifier: "record1" },
       { reference_identifier: "record2" },
       { reference_identifier: "record3" }]
    }
    let(:input_file) { StringIO.new(posted_txns_json) }
    let(:posted_txns_json) { MultiJson.dump(records) }
    let!(:associated_account) { FactoryGirl.create(:account, name: 'account', acct_type_val: 'liability') }
    let!(:unassigned_account) { FactoryGirl.create(:account, name: 'unassigned', acct_type_val: 'expense') }
    let!(:user) { FactoryGirl.create(:user) }

    shared_examples "persisted posted transactions" do
      it "persists all transactions" do
        importer.import
        expect(PostedTransaction.count).to eq 3
      end

      it "persists data correctly" do
        importer.import
        expect(PostedTransaction.first.attributes).
          to include({ "account_id" => associated_account.id,
                       "sale_date" => Date.new(2014, 1, 1),
                       "post_date" => Date.new(2014, 1, 1),
                       "amount" => BigDecimal("1.00"),
                       "reference_identifier" => "record1",
                       "type_identifier" => "type",
                       "category" => "category",
                       "memo" => "memo",
                       "person" => "person"})
      end
    end

    describe "#import" do

      describe "valid posted transactions" do
        it_should_behave_like "persisted posted transactions"
      end

      describe "duplicate posted transactions" do
        before do
          build_importer(records, associated_account).import
        end

        it "does not import the duplicate posted transaction" do
          expect { importer.import }.to_not change { PostedTransaction.count }.from(3)
        end

        it "reports duplication errors" do
          importer.import
          expect(importer.errors).to have(3).errors_on(:reference_identifier)
        end
      end

      describe "invalid posted transactions" do
        before do
          # force PostedTransaction to be invalid
          records.first[:amount] = 'bad number'
        end

        it "returns imported count of zero" do
          expect(importer.import).to eq(0)
        end

        it "does not persist any PostedTransactions" do
          importer.import
          expect(PostedTransaction.count).to eq 0
        end

        it "reports zero imported transactions" do
          importer.import
          expect(importer.imported).to be_empty
        end

        it "reports errors" do
          importer.import
          expect(importer.errors.first[1]).to eq("Amount is not a number")
        end
      end

      describe "invalid posted transactions, abort_on_error flag is not set" do
        before do
          # force PostedTransaction to be invalid
          records.first[:amount] = 'bad number'
        end

        it "returns imported count" do
          expect(importer.import(abort_on_error: false)).to eq(2)
        end

        it "persists only valid PostedTransactions" do
          importer.import(abort_on_error: false)
          expect(PostedTransaction.count).to eq 2
        end

        it "reports two imported transactions if abort_on_error flag is not set" do
          importer.import(abort_on_error: false)
          expect(importer.imported).to have(2).items
        end

        it "reports errors" do
          importer.import(abort_on_error: false)
          expect(importer.errors.first[1]).to eq("Amount is not a number")
        end
      end
    end
  end
end
