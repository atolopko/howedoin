module Service
  class ImportCitiCard
    attr_accessor :results

    def self.load(file)
      new(MultiJson.load(file, symbolize_keys: true))
    end

    def initialize(posted_txns_json)
      @posted_txns_json = posted_txns_json
    end

    def import
      @results = []
      PostedTransaction.transaction do
        @posted_txns_json.each do |t|
          pt = PostedTransaction.new
          pt.account = associated_account
          pt.sale_date = Date.strptime t[:sale_date], "%m/%d/%Y"
          pt.post_date = Date.strptime t[:post_date], "%m/%d/%Y"
          pt.amount = BigDecimal.new(t[:amt].gsub(/[$,]/, '')) if t[:amt]
          pt.reference_identifier = t[:ref_numb]
          pt.type_identifier = t[:type]
          pt.category = t[:category]
          pt.memo = t[:desc]
          pt.person = t[:person]
          begin
            pt.txn = find_or_create_txn(pt)
          rescue StandardError => e
          end
          pt.save
          @results << pt
        end
        if errors?
          raise ActiveRecord::Rollback, "import errors"
        end
        true
      end
    end

    def errors?
      @results.any? { |pt| !pt.persisted? }
    end

    private

    def create_txn(pt)
      txn = Txn.new(date: pt.sale_date)
      txn.entries << Entry.new(account: pt.account,
                               user: User.first,
                               amount: -pt.amount,
                               memo: pt.memo,
                               num: pt.reference_identifier)
      txn.entries << Entry.new(account: Account.where(name: 'unassigned').first,
                               user: User.first,
                               amount: pt.amount)
      txn.save!
      txn
    end

    def find_or_create_txn(pt)
      pt.find_matching_txn || create_txn(pt)
    end

    def associated_account
      @associated_account ||= Account.where("name like 'Citibank MasterCard%'").first
    end

  end
end
