require 'spec_helper'

module PostedTransactions
  describe CiticardRecentActivityParser do

    let(:posted_txns_data) {
      <<-CSV
"Status","Date","Description","Debit","Credit"
"Cleared","03/01/2014","TRADER JOE'S #999  QPS SPRINGFIELD   MA","94.72",""
"Cleared","03/02/2014","Amazon.com             AMZN.COM/BILL WA 
","21.31",""
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
    let(:parser) { CiticardRecentActivityParser.new(csv_filename) }

    after do
      csv_file.unlink
    end

    describe "#import" do
      it "persists data correctly" do
        expect(parser.posted_txns.map { |pt| pt.attributes.values_at('sale_date',
                                                                     'amount',
                                                                     'memo') }).
          to match_array([[Date.new(2014, 3, 1),
                           BigDecimal("-94.72"),
                           "TRADER JOE'S #999  QPS SPRINGFIELD   MA"],
                          [Date.new(2014, 3, 2),
                           BigDecimal("-21.31"),
                           "Amazon.com             AMZN.COM/BILL WA"],
                          [Date.new(2014, 3, 3),
                           BigDecimal("1000.01"),
                           "ELECTRONIC PAYMENT-THANK YOU"]])
      end
    end
    
  end
end

