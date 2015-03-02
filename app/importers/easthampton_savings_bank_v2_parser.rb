require 'csv'
require 'parser'

module Importers
  class EasthamptonSavingsBankV2Parser < Parser

    def posted_txns
      CSV.foreach(@posted_txns_csv, skip_blanks: true, headers: true) do |row|
        @posted_txns << populate(row.to_hash)
      end
      @posted_txns
    end

    def ending_balance
      to_amount @posted_txns.last['Ending Balance']      
    end

    private

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
