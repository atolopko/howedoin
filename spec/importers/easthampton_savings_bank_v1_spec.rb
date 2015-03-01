require 'spec_helper'

module Importers
  describe EasthamptonSavingsBankV1 do

    let(:posted_txns_data) {
      <<-CSV
02/18/2012,,"Starting Balance",,+$2001.01
02/20/2012,,"ABC Store",-$1001.01,+$1000
02/21/2012,,"ATM Withdrawal",-$100.00,+$900
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
    let(:statement) { FactoryGirl.create(:statement, account: account) }
    let(:importer) { EasthamptonSavingsBankV1.new(csv_file, statement) }

    after do
      csv_file.unlink
    end



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
                        Date.new(2012, 2, 20),
                        BigDecimal("-1001.01"),
                        "ABC Store"],
                       [account.id,
                        statement.id,
                        Date.new(2012, 2, 21),
                        BigDecimal("-100"),
                        "ATM Withdrawal"
                        ])
        end
      end
      
    end
  end
end
