require 'spec_helper'

module Importers
  describe CiticardHistoricalStatementParser do

    let(:posted_txns_data) {
      <<-CSV
"12/01/2014","$94.72","TRADER JOE'S #999  QPS SPRINGFIELD   MA","2"
"12/02/2014","$21.31","Amazon.com             AMZN.COM/BILL WA","2"
"12/03/2014","$-1000.01","ELECTRONIC PAYMENT-THANK YOU","1"
      CSV
    }
    let(:csv_file) {
      f = Tempfile.new('2014-12-31.')
      f.write(posted_txns_data)
      f.close
      f
    }
    let(:csv_filename) { csv_file.path }
    let(:parser) { CiticardHistoricalStatementParser.new(csv_filename) }

    after do
      csv_file.unlink
    end

    describe "#posted_txns" do
      it "persists data correctly" do
        expect(parser.posted_txns.map { |pt| pt.attributes.values_at('post_date',
                                                                     'amount',
                                                                     'type_identifier',
                                                                     'memo') }).
          to include([Date.new(2014, 12, 1),
                      BigDecimal("94.72"),
                      "2",
                      "TRADER JOE'S #999  QPS SPRINGFIELD   MA"],
                     [Date.new(2014, 12, 2),
                      BigDecimal("21.31"),
                      "2",
                      "Amazon.com             AMZN.COM/BILL WA"],
                     [Date.new(2014, 12, 3),
                      BigDecimal("-1000.01"),
                      "1",
                      "ELECTRONIC PAYMENT-THANK YOU"])
      end
    end
    
  end
end
