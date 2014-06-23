require 'spec_helper'

module Service
  describe CiticardImporter do

    let(:posted_txns) { 
      [{ sale_date: "01/17/2014",
         desc: "NEW YORK TIMES DIGITAL 100001 NY",
         amt: "$0.99",
         type: "2",
         post_date: "01/18/2014",
         category: "DIRECT MARKETING-CONTINUITY SUBSCRIPTION",
         ref_numb: "xyz123",
         person: "Joe Banks"}] }
    let(:input_file) { StringIO.new(posted_txns_json) }
    let(:posted_txns_json) { MultiJson.dump(posted_txns) }
    let!(:associated_account) { FactoryGirl.create(:account, name: 'Citibank MasterCard', acct_type_val: 'liability') }
    let!(:user) { FactoryGirl.create(:user) }
    let(:importer) { CiticardImporter.new(posted_txns) }

    describe "#import" do
      describe "valid posted transactions without existing transactions" do

        it "persists data correctly" do
          importer.import
          expect(PostedTransaction.first.attributes).
            to include({ "account_id" => associated_account.id,
                         "sale_date" => Date.new(2014, 1, 17),
                         "post_date" => Date.new(2014, 1, 18),
                         "amount" => BigDecimal("0.99"),
                         "reference_identifier" => "xyz123",
                         "type_identifier" => "2",
                         "category" => "DIRECT MARKETING-CONTINUITY SUBSCRIPTION",
                         "memo" => "NEW YORK TIMES DIGITAL 100001 NY",
                         "person" => "Joe Banks"})
        end
      end


    end

  end
end
