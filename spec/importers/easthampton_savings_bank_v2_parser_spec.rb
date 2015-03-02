require 'spec_helper'

module Importers
  describe EasthamptonSavingsBankV2Parser do

    let(:posted_txns_data) {
      <<-CSV
"Account Number","Date","Transaction Description","Transaction Amount","Ending Balance"
"999999999","Dec 30","ABC Store","-1001.01","1000.00",""
"999999999","Jan 25","Paycheck","119.11","1119.11",""
      CSV
    }
    let(:csv_file) {
      f = Tempfile.new('2013-01-31.')
      f.write(posted_txns_data)
      f.close
      f
    }
    let(:csv_filename) { csv_file.path }
    let(:parser) { EasthamptonSavingsBankV2Parser.new(csv_filename) }

    after do
      csv_file.unlink
    end

    describe "#posted_txns" do
      it "imports data correctly" do
        expect(parser.posted_txns.map { |pt| pt.attributes.values_at('post_date',
                                                                     'amount',
                                                                     'memo') }).
          to include([Date.new(2012, 12, 30),
                      BigDecimal("-1001.01"),
                      "ABC Store"],
                     [Date.new(2013, 1, 25),
                      BigDecimal("119.11"),
                      "Paycheck"])
      end
    end

    # TODO: test this at the Parser level only
    describe "#statement_date" do
      it "infers statement date from input file name" do
        expect(parser.statement_date).to eq Date.new(2013, 1, 31)
      end
    end

    describe "#ending_balance" do
      it "infers ending balance from input file data" do
        expect(parser.ending_balance).to eq BigDecimal('1119.11')
      end
    end

  end
end
