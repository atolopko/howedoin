require 'csv'
require 'posted_transaction_importer'

module Importers
  class EasthamptonSavingsBankV2 < PostedTransactionImporter

    def initialize(posted_txns_csv_io, statement)
      posted_txns = []
      CSV.foreach(posted_txns_csv_io, skip_blanks: true, headers: true) do |row|
        posted_txns << row.to_hash
      end
      super(posted_txns, statement)
    end

    private

    def populate(pt, r)
      pt.post_date = Date.strptime r['Date'], "%b %d"
      until pt.post_date <= @statement.stmt_date
        pt.post_date = pt.post_date.prev_year
      end
      pt.amount = BigDecimal.new(r['Transaction Amount'].gsub(/[$,]/, '')) if r['Transaction Amount']
      pt.memo = r['Transaction Description']
    end
   
  end
end
