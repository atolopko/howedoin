require 'spec_helper'

module Service
  describe ImportCitiCard do

    let(:posted_txns) { 
      [{:sale_date=>"01/17/2014",
         :desc=>"NEW YORK TIMES DIGITAL 100001 NY",
         :amt=>"$0.99",
         :type=>"2",
         :post_date=>"01/18/2014",
         :category=>"DIRECT MARKETING-CONTINUITY SUBSCRIPTION",
         :ref_numb=>"xyz123",
         :person=>"Joe Banks"},
       {:sale_date=>"01/14/2014",
         :desc=>"MEXI CALI RESTAURANT",
         :amt=>"$28.73",
         :type=>"2",
         :post_date=>"01/14/2014",
         :category=>"EATING PLACE,RESTAURANT"},
       {:sale_date=>"01/19/2014",
         :desc=>"ELECTRONIC PAYMENT-THANK YOU",
         :amt=>"-$1,429.73",
         :type=>"1",
         :post_date=>"01/20/2014"}] }
    let(:input_file) { StringIO.new(posted_txns_json) }
    let(:posted_txns_json) { MultiJson.dump(posted_txns) }
    let!(:associated_account) { FactoryGirl.create(:account, name: 'Citibank MasterCard', acct_type_val: 'liability') }
    let!(:unassigned_account) { FactoryGirl.create(:account, name: 'unassigned', acct_type_val: 'expense') }
    let!(:user) { FactoryGirl.create(:user) }

    shared_examples "persisted posted transactions" do
      it "persists all transactions" do
        expect(PostedTransaction.count).to eq 3
      end

      it "persists data correctly" do
        expect(PostedTransaction.first.attributes).
          to include({"sale_date"=>Date.new(2014, 1, 17),
                       "post_date"=>Date.new(2014, 1, 18),
                       "amount"=>BigDecimal("0.99"),
                       "reference_identifier"=>"xyz123",
                       "type_identifier"=>"2",
                       "category"=>"DIRECT MARKETING-CONTINUITY SUBSCRIPTION",
                       "memo"=>"NEW YORK TIMES DIGITAL 100001 NY",
                       "person"=>"Joe Banks"})
      end

      it "associates with correct account" do
        expect(PostedTransaction.first.account).to eq associated_account
      end
    end

    describe "#import" do
      describe "valid posted transactions without existing transactions" do
        before do
          ImportCitiCard.new(posted_txns).import
        end

        it_should_behave_like "persisted posted transactions"

        it "creates associated Txn" do
          expect(PostedTransaction.first.txn.date).to eq Date.new(2014, 1, 17)
        end

        it "creates associated Txn entries" do
          expect(PostedTransaction.first.txn.entries[0].attributes.symbolize_keys).
            to include({acct_id: associated_account.id,
                         user_id: user.id,
                         amount: -0.99,
                         memo: 'NEW YORK TIMES DIGITAL 100001 NY',
                         num: 'xyz123'})
          expect(PostedTransaction.first.txn.entries[1].attributes.symbolize_keys).
            to include({acct_id: unassigned_account.id,
                         user_id: user.id,
                         amount: 0.99,
                         memo: nil,
                         num: nil})
        end
      end

      describe "valid posted transactions with existing transactions" do
        let!(:existing_txn) { FactoryGirl.create(:txn,
                                                 date: Date.new(2014, 1, 17),
                                                 amount: 0.99,
                                                 from_account: associated_account) }

        before do
          ImportCitiCard.new(posted_txns).import
        end

        it_should_behave_like "persisted posted transactions"

        it "associates with existing Txn" do
          expect(PostedTransaction.first.txn).to eq existing_txn
        end
      end

      describe "invalid transactions" do
        before do
          posted_txns[1][:amt] = nil
        end

        it "returns false" do
          expect(ImportCitiCard.new(posted_txns).import).to be_false
        end

        it "does not persist any PostedTransactions" do
          ImportCitiCard.new(posted_txns).import
          expect(PostedTransaction.count).to eq 0
        end

        it "does not persist any Txns" do
          ImportCitiCard.new(posted_txns).import
          expect(Txn.count).to eq 0
        end

        it "provides errors in returned posted transactions" do
          icc = ImportCitiCard.new(posted_txns)
          icc.import
          expect(icc.results[1].errors.messages).to eq({amount: ["can't be blank", "is not a number"],
                                                       txn: ["can't be blank"]})
        end
      end
    end

    describe ".load" do
      it "parses json and stores as hash" do
        expect(ImportCitiCard).to receive(:new).with(posted_txns)
        ImportCitiCard.load(input_file)
      end
    end

  end
end
