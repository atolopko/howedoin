require 'spec_helper'

module Importers
  describe CiticardRecentActivity do

    let(:posted_txns_data) {
      <<-CSV
"Status","Date","Description","Debit","Credit"
"Cleared","03/01/2014","TRADER JOE'S #999  QPS SPRINGFIELD   MA","94.72",""
"Cleared","03/02/2014","Amazon.com             AMZN.COM/BILL WA","21.31",""
"Cleared","03/03/2014","ELECTRONIC PAYMENT-THANK YOU","","1,000.01"
"Pending","03/04/2015","DENNY'S","40.01",""
      CSV
    }
    let(:csv_file) {
      f = Tempfile.new('posted_txns_data')
      f.write(posted_txns_data)
      f.close
      f
    }
    let(:csv_filename) { csv_file.path }
    let(:account) { FactoryGirl.create(:account, name: 'Citibank MasterCard', acct_type_val: 'liability') }
    let(:statement) { FactoryGirl.create(:statement, account: account) }
    let(:importer) { CiticardRecentActivity.new(csv_filename, statement) }

    after do
      csv_file.unlink
    end

    describe "#import" do
      describe "valid posted transactions without existing transactions" do

        it "persists data correctly" do
          importer.import

          # to help debug a failing test
          fail("Error while running test:\n#{importer.format_errors}") if importer.errors?
          
          expect(PostedTransaction.all.
                 map { |pt| pt.attributes.values_at('account_id',
                                                    'stmt_id',
                                                    'sale_date',
                                                    'amount',
                                                    'memo') }).
            to match_array([[account.id,
                             statement.id,
                             Date.new(2014, 3, 1),
                             BigDecimal("94.72"),
                             "TRADER JOE'S #999  QPS SPRINGFIELD   MA"],
                            [account.id,
                             statement.id,
                             Date.new(2014, 3, 2),
                             BigDecimal("21.31"),
                             "Amazon.com             AMZN.COM/BILL WA"],
                            [account.id,
                             statement.id,
                             Date.new(2014, 3, 3),
                             BigDecimal("-1000.01"),
                             "ELECTRONIC PAYMENT-THANK YOU"]])
        end
      end
      
    end
  end
end
