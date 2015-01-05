require 'csv'

module Service
  # Imports raw transactions from a Citicard CSV downloaded statement as PostedTransactions.
  class CiticardImporter < PostedTransactionImporter

    def initialize(posted_txns_csv_io)
      csv = CSV.new(posted_txns_csv_io, headers: [:post_date, :amt, :memo, :type], skip_blanks: true)
      posted_txns = csv.readlines.map { |r| r.to_hash }
      super(posted_txns, associated_account)
    end

    private

    def populate(pt, r)
      pt.post_date = Date.strptime r[:post_date], "%Y-%m-%d"
      pt.amount = BigDecimal.new(r[:amt].gsub(/[$,]/, '')) if r[:amt]
      pt.memo = r[:memo]
      pt.type_identifier = r[:type]
    end
    
    def associated_account
      # TODO: this should come from a config file
      Account.where("name like 'Citibank MasterCard%'").first
    end

  end
end
