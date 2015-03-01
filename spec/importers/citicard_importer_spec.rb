require 'spec_helper'

module Importers
  describe CiticardImporter do

    let(:posted_txns_data) {
      <<-CSV
"12/01/2014","$94.72","TRADER JOE'S #999  QPS SPRINGFIELD   MA","2"
"12/02/2014","$21.31","Amazon.com             AMZN.COM/BILL WA","2"
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
    let(:importer) { CiticardImporter.new(csv_filename, statement) }

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
                                                                          'type_identifier',
                                                                          'memo') }).
            to include([account.id,
                        statement.id,
                        Date.new(2014, 12, 1),
                        BigDecimal("94.72"),
                        "2",
                        "TRADER JOE'S #999  QPS SPRINGFIELD   MA"],
                       [account.id,
                        statement.id,
                        Date.new(2014, 12, 2),
                        BigDecimal("21.31"),
                        "2",
                        "Amazon.com             AMZN.COM/BILL WA"])
        end
      end
      
    end
  end
end
