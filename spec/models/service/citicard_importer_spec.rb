require 'spec_helper'

module Service
  describe CiticardImporter do

    let(:posted_txns_data) {
      <<-CSV
"2014-12-01","$94.72","TRADER JOE'S #999  QPS SPRINGFIELD   MA","2"
"2014-12-02","$21.31","Amazon.com             AMZN.COM/BILL WA","2"
      CSV
    }
    let(:input_file) { StringIO.new(posted_txns_data) }
    let!(:associated_account) { FactoryGirl.create(:account, name: 'Citibank MasterCard', acct_type_val: 'liability') }
    let(:importer) { CiticardImporter.new(input_file) }

    describe "#import" do
      describe "valid posted transactions without existing transactions" do

        it "persists data correctly" do
          importer.import
          expect(PostedTransaction.all.map { |pt| pt.attributes.values_at('account_id', 'post_date', 'amount', 'memo') }).
            to include([associated_account.id,
                        Date.new(2014, 12, 1),
                        BigDecimal("94.72"),
#                         "type_identifier" => "2",
                         "TRADER JOE'S #999  QPS SPRINGFIELD   MA"],
                       [associated_account.id,
                        Date.new(2014, 12, 2),
                        BigDecimal("21.31"),
#                         "type_identifier" => "2",
                         "Amazon.com             AMZN.COM/BILL WA"])
        end
      end
      
    end
  end
end
