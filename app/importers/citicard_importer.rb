require 'csv'
require 'posted_transaction_importer'

module Importers
  # Imports raw transactions from a Citicard CSV downloaded statement as PostedTransactions.
  class CiticardImporter < PostedTransactionImporter

    HEADERS = [:post_date, :amt, :memo, :type]

    def initialize(posted_txns_csv, statement)
      posted_txns = []
      CSV.foreach(posted_txns_csv, headers: HEADERS, skip_blanks: true) do |row|
        posted_txns << row.to_hash
      end
      super(posted_txns, statement)
    end

    private

    def populate(pt, r)
      pt.post_date = Date.strptime r[:post_date], "%m/%d/%Y"
      pt.amount = BigDecimal.new(r[:amt].gsub(/[$,]/, '')) if r[:amt]
      pt.memo = r[:memo]
      pt.type_identifier = r[:type]
    end
   
  end
end
