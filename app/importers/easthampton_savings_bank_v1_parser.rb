require 'csv'
require 'parser'

module Importers
  class EasthamptonSavingsBankV1Parser < Parser

    HEADERS = [:post_date, :empty, :memo, :amt, :balance]

    def posted_txns
      CSV.foreach(@posted_txns_csv, headers: HEADERS, skip_blanks: true) do |row|
        @posted_txns << populate(row.to_hash) unless row[:memo] == "Starting Balance"
      end
      @posted_txns
    end

    private

    def populate(r)
      pt = PostedTransaction.new
      pt.post_date = Date.strptime r[:post_date], "%m/%d/%Y"
      pt.amount = BigDecimal.new(r[:amt].gsub(/[$,]/, '')) if r[:amt]
      pt.memo = r[:memo]
      pt
    end
  end
end
