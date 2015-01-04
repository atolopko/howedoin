module Service
  # Imports raw transactions from a financial service account as
  # PostedTransactions.
  class PostedTransactionImporter
    attr_accessor :results

    def self.load(file)
      new(MultiJson.load(file, symbolize_keys: true))
    end

    def initialize(posted_txns_json, associated_account)
      @posted_txns_json = posted_txns_json
      @associated_account = associated_account
    end

    def import(fail_fast = true)
      @results = []
      PostedTransaction.transaction do
        @posted_txns_json.each do |record|
          pt = PostedTransaction.new
          pt.account = @associated_account
          populate(pt, record)
          pt.save
          @results << pt
        end
        if errors? && fail_fast
          raise ActiveRecord::Rollback, "import errors"
        end
        true
      end
    end

    def errors
      @results.select { |pt| pt.invalid? }.map(&:errors)
    end

    def errors?
      @results.any? { |pt| pt.invalid? }
    end

    private

    def populate(posted_txn, record)
      raise NotImplementedError, "subclass must implement"
    end

    # def find_txn_factory(pt)
    #   return DefaultTxnFactory.new
    # end

    # def create_txn(pt)
    #   txn_factory = find_txn_factory(pt)
    #   txn_factory.build(pt)
    # end

    # def find_or_create_txn(pt)
    #   # TODO: txn matching could be more accurate if performed by each
    #   # TxnFactory, since it can match more specific attributes &
    #   # values
    #   pt.find_matching_txn || create_txn(pt)
    # end

  end
end
