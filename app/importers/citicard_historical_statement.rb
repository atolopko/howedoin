require 'csv'
require 'posted_transaction_importer'

module Importers
  # Imports raw transactions from a Citicard CSV downloaded
  # transaction file as PostedTransactions. Note that there are two
  # pages from which account activity can be download from the web
  # site: 1) From the Account Details page and 2) From the Statement
  # Downloads page. This importer class is for the method 2 and should
  # only be used for importing historical date (more than 6 months
  # old) since that data is only available via the Statement Downloads
  # page. Method 1 is otherwise preferred since it provides the sale
  # date instead of the posted date.
  class CiticardHistoricalStatement < PostedTransactionImporter

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
