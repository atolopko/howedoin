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
    let!(:associated_account) { Account.create(name: 'Citibank MasterCard') }

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
      describe "valid transactions" do
        before do
          ImportCitiCard.new(posted_txns).import
        end
        it_should_behave_like "persisted posted transactions"
      end

      describe "invalid transactions" do
        before do
          posted_txns[1][:amt] = nil
        end

        it "returns false" do
          expect(ImportCitiCard.new(posted_txns).import).to be_false
        end

        it "does not persist any transactions" do
          expect(PostedTransaction.count).to eq 0
          ImportCitiCard.new(posted_txns).import
        end

        it "provides errors in returned posted transactions" do
          icc = ImportCitiCard.new(posted_txns)
          icc.import
          expect(icc.results[1].errors.messages).to eq({:amount=>["can't be blank", "is not a number"]})
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
