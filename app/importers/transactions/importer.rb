module Transactions
  class Importer
    def self.import_all
      PostedTransaction.transaction do
        unimported_posted_txns.each do |posted_txn|
          Importer.new(posted_txn).import
          binding.pry
          raise ActiveRecord::Rollback
        end
      end
    end

    def self.unimported_posted_txns
      PostedTransaction.where(txn_id: nil)
    end

    attr_accessor :posted_txn, :txn

    def initialize(posted_txn)
      @posted_txn = posted_txn
    end

    def import
      @txn = posted_txn.txn ||
        find_existing ||
        find_factory.try { |f| f.build(posted_txn) }
      link
    end

    def find_existing
      # must not be linked
      nil
    end

    def find_factory
      Service::DefaultTxnFactory.new(posted_txn.account,
                                     User.payment_default)
    end

    def link
      return unless txn
      return if posted_txn.txn.present?
      posted_txn.txn = txn
      posted_txn.save!
    end
  end
end
