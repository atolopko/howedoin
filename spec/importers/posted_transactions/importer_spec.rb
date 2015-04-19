require 'spec_helper'

module PostedTransactions
  describe Importer do

    def build_posted_txns
      [{ reference_identifier: "record1" },
       { reference_identifier: "record2" },
       { reference_identifier: "record3" }].map do |r|
        pt = PostedTransaction.new
        pt.sale_date = Date.new(2015, 1, 1)
        pt.post_date = Date.new(2015, 1, 2)
        pt.memo = 'memo'
        pt.amount = BigDecimal.new("1.00")
        pt.reference_identifier = r[:reference_identifier]
        pt.type_identifier = 'type'
        pt.category = 'category'
        pt.person = 'person'
        pt
      end
    end

    let(:posted_txns) { build_posted_txns }
    let(:importer) { Importer.new("account", Date.new(2015, 01, 01), BigDecimal("100.00")) }
    let!(:account) { FactoryGirl.create(:account, name: 'account', acct_type_val: 'liability') }
    let!(:user) { FactoryGirl.create(:user) }

    shared_examples "persisted posted transactions" do
      it "persists all transactions" do
        importer.import(posted_txns)
        expect(PostedTransaction.count).to eq 3
      end

      it "persists data correctly" do
        importer.import(posted_txns)
        expect(PostedTransaction.first.attributes).
          to include({ "account_id" => account.id,
                       "sale_date" => Date.new(2015, 1, 1),
                       "post_date" => Date.new(2015, 1, 2),
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
          Importer.
            new("account", Date.new(2014, 12, 31), BigDecimal("100.00")).
            import(build_posted_txns)
        end

        it "does not import the duplicate posted transaction" do
          expect { importer.import(posted_txns) }.to_not change { PostedTransaction.count }.from(3)
        end

        it "reports duplication errors" do
          importer.import(posted_txns)
          expect(importer.errors).to have(3).errors_on(:reference_identifier)
        end
      end

      describe "posted transactions already persisted" do
        before do
          Importer.
            new("account", Date.new(2014, 12, 31), BigDecimal("100.00")).
            import(posted_txns)
        end

        it "does not associate the already-persisted posted transactions" do
          expect { importer.import(posted_txns) }.to_not change { posted_txns.map(&:statement) }
        end

        it "reports duplication errors" do
          importer.import(posted_txns)
          expect(importer.errors).
            to eq posted_txns.map { |pt| [pt, "PostedTransaction expected to be not persisted"] }
        end
      end

      describe "invalid posted transactions" do
        before do
          # force PostedTransaction to be invalid
          posted_txns.first[:amount] = 'bad number'
        end

        it "returns imported count of zero" do
          expect(importer.import(posted_txns)).to eq(0)
        end

        it "does not persist any PostedTransactions" do
          importer.import(posted_txns)
          expect(PostedTransaction.count).to eq 0
        end

        it "reports zero imported transactions" do
          importer.import(posted_txns)
          expect(importer.imported).to be_empty
        end

        it "reports errors" do
          importer.import(posted_txns)
          expect(importer.errors.first[1]).to eq("Amount is not a number")
        end
      end

      describe "invalid posted transactions, abort_on_error flag is not set" do
        before do
          # force PostedTransaction to be invalid
          posted_txns.first.amount = 'bad number'
        end

        it "returns imported count" do
          expect(importer.import(posted_txns, abort_on_error: false)).to eq(2)
        end

        it "persists only valid PostedTransactions" do
          importer.import(posted_txns, abort_on_error: false)
          expect(PostedTransaction.count).to eq 2
        end

        it "reports two imported transactions if abort_on_error flag is not set" do
          importer.import(posted_txns, abort_on_error: false)
          expect(importer.imported).to have(2).items
        end

        it "reports errors" do
          importer.import(posted_txns, abort_on_error: false)
          expect(importer.errors.first[1]).to eq("Amount is not a number")
        end
      end
    end
  end
end
