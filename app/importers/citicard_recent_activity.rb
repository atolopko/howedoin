require 'csv'
require 'posted_transaction_importer'

module Importers
  # Imports raw transactions from a Citicard CSV downloaded
  # transaction file as PostedTransactions. Note that there are two
  # pages from which account activity can be download from the web
  # site: 1) From the Account Details page and 2) From the Statement
  # Downloads page. This importer class is for the method 1 and is
  # preferred since it provides the sale date instead of the posted
  # date. However, method 2 is required for importing historical date
  # (more than 6 months old) since that data is only available via the
  # Statement Downloads page.
  class CiticardRecentActivity < PostedTransactionImporter

    def initialize(posted_txns_csv, statement)
      csv_str = to_s_with_normalized_newlines(posted_txns_csv)
      posted_txns = []
      CSV.new(csv_str, headers: true, skip_blanks: true).each do |row|
        posted_txns << row.to_hash if row['Status'] == 'Cleared'
      end
      super(posted_txns, statement)
    end

    private

    def populate(pt, r)
      pt.sale_date = Date.strptime r['Date'], "%m/%d/%Y"
      amount = r['Debit'].present? ? r['Debit'] : "-#{r['Credit']}"
      pt.amount = BigDecimal.new(amount.gsub(/[,]/, '')) if amount
      pt.memo = r['Description']
    end

    def to_s_with_normalized_newlines(file)
      csv_str = File.new(file).read
      csv_str.encode(universal_newline: true)
    end

  end
end
