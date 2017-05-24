require 'spec_helper'

module PostedTransactions
  describe EasthamptonSavingsBankV2Parser do

    let(:posted_txns_data) {
      <<-CSV
"Date","Type","Description","","Withdrawals","Deposits","Current Balance","Inquire"
"05/19/2017","Credit Interest","Credit Interest","","","$.43","$150.43",""
"05/18/2017","Check","Check 100","","$50.00","","$150.00",""
"05/08/2017","Bill Payment Withdrawal","Credit Card Company","","$1,300.00","","$200.00",""
"05/01/2017","External Deposit","Paycheck","","","$1,000.00","$1,500",""
      CSV
    }
    let(:csv_file) {
      f = Tempfile.new('2017-05-31.')
      f.write(posted_txns_data)
      f.close
      f
    }
    let(:csv_filename) { csv_file.path }
    let(:parser) { EasthamptonSavingsBankV3Parser.new(csv_filename) }

    after do
      csv_file.unlink
    end

    describe "#posted_txns" do
      it "imports data correctly" do
        expect(parser.posted_txns.map { |pt| pt.attributes.values_at('post_date',
                                                                     'amount',
                                                                     'memo') }).
          to include([Date.new(2017, 5, 19),
                      BigDecimal("0.43"),
                      "Credit Interest"],
                     [Date.new(2017, 5, 18),
                      BigDecimal("-50.00"),
                      "Check 100"],
                     [Date.new(2017, 5, 8),
                      BigDecimal("-1300.00"),
                      "Credit Card Company"],
                     [Date.new(2017, 5, 1),
                      BigDecimal("1000.00"),
                      "Paycheck"])
      end
    end

    # TODO: test this at the Parser level only
    describe "#statement_date" do
      it "infers statement date from input file name" do
        expect(parser.statement_date).to eq Date.new(2017, 5, 31)
      end
    end

    describe "#ending_balance" do
      it "infers ending balance from input file data" do
        expect(parser.ending_balance).to eq BigDecimal('150.43')
      end
    end

  end
end
