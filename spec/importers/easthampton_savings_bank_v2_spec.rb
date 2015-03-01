require 'spec_helper'

module Importers
  describe EasthamptonSavingsBankV2 do

    let(:posted_txns_data) {
      <<-CSV
"Account Number","Date","Transaction Description","Transaction Amount","Ending Balance"
"999999999","Dec 30","ABC Store","-1001.01","1000.00",""
"999999999","Jan 25","Paycheck","119.11","1119.11",""
      CSV
    }
    let(:csv_file) {
      f = Tempfile.new('posted_txns_data')
      f.write(posted_txns_data)
      f.close
      f
    }
    let(:csv_filename) { csv_file.path }
    let(:account) { FactoryGirl.create(:account, name: 'ESB Checking', acct_type_val: 'liability') }
    let(:statement) { FactoryGirl.create(:statement, account: account, stmt_date: Date.new(2013, 1, 29)) }
    let(:importer) { EasthamptonSavingsBankV2.new(csv_file, statement) }

    describe "#import" do
      describe "valid posted transactions without existing transactions" do

        it "persists data correctly" do
          importer.import

          # to help debug a failing test
          fail("Error while running test:\n#{importer.format_errors}") if importer.errors?

          expect(PostedTransaction.all.map { |pt| pt.attributes.values_at('account_id',
                                                                          'stmt_id',
                                                                          'post_date',
                                                                          'amount',
                                                                          'memo') }).
            to include([account.id,
                        statement.id,
                        Date.new(2012, 12, 30),
                        BigDecimal("-1001.01"),
                        "ABC Store"],
                       [account.id,
                        statement.id,
                        Date.new(2013, 1, 25),
                        BigDecimal("119.11"),
                        "Paycheck"
                        ])
        end
      end
      
    end
  end
end
