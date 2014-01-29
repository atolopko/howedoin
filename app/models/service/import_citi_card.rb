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
          pt.txn = find_or_create_txn(pt)
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

    def find_txn_factory(pt)
      return DefaultTxnFactory.new
    end

    def create_txn(pt)
      txn_factory = find_txn_factory(pt)
      txn = txn_factory.build(pt)
      txn.save!
      txn
    end

    def find_or_create_txn(pt)
      # TODO: txn matching could be more accurate if performed by each
      # TxnFactory, since it can match more specific attributes &
      # values
      pt.find_matching_txn || create_txn(pt)
    rescue StandardError => e
      Rails.logger.error("#find_or_create_txn: #{e.message}")
      nil
    end

    def associated_account
      @associated_account ||= Account.where("name like 'Citibank MasterCard%'").first
    end

  end
end
