require 'csv'

module PostedTransactions
  class EasthamptonSavingsBankV2Parser < Parser

    def posted_txns
      @posted_txn ||= parse
    end

    def ending_balance
      posted_txns
      @ending_balance
    end

    private

    def parse
      posted_txns = []
      CSV.foreach(@posted_txns_csv, skip_blanks: true, headers: true) do |row|
        posted_txns << populate(row.to_hash)
        @ending_balance = to_amount row['Ending Balance']      
      end
      posted_txns
    end

    def populate(r)
      pt = PostedTransaction.new
      pt.post_date = Date.strptime r['Date'], "%b %d"
      until pt.post_date <= statement_date
        pt.post_date = pt.post_date.prev_year
      end
      pt.amount = to_amount r['Transaction Amount']
      pt.memo = r['Transaction Description']
      pt
    end
    
  end
end
