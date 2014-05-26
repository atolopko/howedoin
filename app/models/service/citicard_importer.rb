module Service
  # Imports raw transactions from a Citicard as PostedTransactions.
  class CiticardImporter < PostedTransactionImporter

    def initialize(posted_txns_json)
      super(posted_txns_json, associated_account)
    end

    private

    def populate(pt, r)
      pt.sale_date = Date.strptime r[:sale_date], "%m/%d/%Y"
      pt.post_date = Date.strptime r[:post_date], "%m/%d/%Y"
      pt.amount = BigDecimal.new(r[:amt].gsub(/[$,]/, '')) if r[:amt]
      pt.reference_identifier = r[:ref_numb]
      pt.type_identifier = r[:type]
      pt.category = r[:category]
      pt.memo = r[:desc]
      pt.person = r[:person]
    end
    
    def associated_account
      Account.where("name like 'Citibank MasterCard%'").first
    end

  end
end
