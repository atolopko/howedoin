require 'spec_helper'

module PostedTransactions
  describe EasthamptonSavingsBankV1Parser do

    let(:posted_txns_data) {
      <<-CSV
02/18/2012,,"Starting Balance",,+$2001.01
02/20/2012,,"ABC Store",-$1001.01,+$1000
02/21/2012,,"ATM Withdrawal",-$100.00,+$900
      CSV
    }
    let(:csv_file) {
      f = Tempfile.new('2013-01-31.')
      f.write(posted_txns_data)
      f.close
      f
    }
    let(:csv_filename) { csv_file.path }
    let(:parser) { EasthamptonSavingsBankV1Parser.new(csv_filename) }

    after do
      csv_file.unlink
    end

    describe "#posted_txns" do
      it "persists data correctly" do
        expect(parser.posted_txns.map { |pt| pt.attributes.values_at('post_date',
                                                                     'amount',
                                                                     'memo') }).
          to include([Date.new(2012, 2, 20),
                      BigDecimal("-1001.01"),
                      "ABC Store"],
                     [Date.new(2012, 2, 21),
                      BigDecimal("-100"),
                      "ATM Withdrawal"])
      end
    end

    describe "#ending_balance" do
      it "infers ending balance from input file data" do
        expect(parser.ending_balance).to eq BigDecimal('900.00')
      end
    end

  end
end
