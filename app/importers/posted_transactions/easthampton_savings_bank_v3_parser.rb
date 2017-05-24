require 'csv'

module PostedTransactions
  class EasthamptonSavingsBankV3Parser < Parser

    def posted_txns
      @posted_txn ||= parse
    end

    def ending_balance
      posted_txns
      @ending_balance || to_amount('0.00')
    end

    private

    def parse
      posted_txns = []
      CSV.foreach(@posted_txns_csv, skip_blanks: true, headers: true) do |row|
        posted_txns << populate(row.to_hash)
        @ending_balance ||= to_amount row['Current Balance']
      end
      posted_txns
    end

    def populate(r)
      pt = PostedTransaction.new
      pt.post_date = DateTime.strptime(r['Date'], '%m/%d/%Y')
      pt.amount = 
        if r['Withdrawals'].present?
          -(to_amount r['Withdrawals'])
        else
          to_amount r['Deposits']
        end
      pt.memo = r['Description']
      pt
    end
    
  end
end
