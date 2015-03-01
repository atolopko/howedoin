require 'csv'
require 'posted_transaction_importer'

module Importers
  class EasthamptonSavingsBankV1 < PostedTransactionImporter

    HEADERS = [:post_date, :empty, :memo, :amt, :balance]

    def initialize(posted_txns_csv, statement)
      posted_txns = []
      CSV.foreach(posted_txns_csv, headers: HEADERS, skip_blanks: true) do |row|
        posted_txns << row.to_hash unless row[:memo] == "Starting Balance"
      end
      super(posted_txns, statement)
    end

    private

    def populate(pt, r)
      pt.post_date = Date.strptime r[:post_date], "%m/%d/%Y"
      pt.amount = BigDecimal.new(r[:amt].gsub(/[$,]/, '')) if r[:amt]
      pt.memo = r[:memo]
    end
   
  end
end
