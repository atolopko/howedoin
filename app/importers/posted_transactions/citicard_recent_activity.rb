require 'csv'

module PostedTransactions
  # Parses raw transactions from a Citicard CSV downloaded
  # transaction file as PostedTransactions. Note that there are two
  # pages from which account activity can be download from the web
  # site: 1) From the Account Details page and 2) From the Statement
  # Downloads page. This importer class is for the method 1 and is
  # preferred since it provides the sale date instead of the posted
  # date. However, method 2 is required for importing historical date
  # (more than 6 months old) since that data is only available via the
  # Statement Downloads page.
  class CiticardRecentActivityParser < Parser

    def posted_txns
      @posted_txns ||= parse
    end

    private

    def parse
      posted_txns = []
      csv_str = to_s_with_normalized_newlines(@posted_txns_csv)
      CSV.new(csv_str, headers: true, skip_blanks: true).each do |row|
        posted_txns << populate(row.to_hash) if row['Status'] == 'Cleared'
      end
      posted_txns
    end

    def populate(r)
      pt = PostedTransaction.new
      pt.sale_date = Date.strptime r['Date'], "%m/%d/%Y"
      amount = r['Debit'] or r['Credit']
      if amount
        pt.amount = BigDecimal.new(amount.gsub(/[,]/, '')).abs
        pt.amount *= -1 if r['Debit']
      end
      pt.memo = r['Description'].gsub(" \n", '')
      pt
    end

    def to_s_with_normalized_newlines(file)
      csv_str = File.new(file).read
      csv_str.encode(universal_newline: true)
    end

  end
end
