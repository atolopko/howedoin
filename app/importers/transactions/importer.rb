module Transactions
  class Importer

    def self.import_all
      PostedTransaction.transaction do
        unimported_posted_txns.each do |posted_txn|
          Importer.new(posted_txn).import
#          raise ActiveRecord::Rollback
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
        build_txn
      link
      if txn
        Rails.logger.info("posted_txn #{posted_txn.id} => txn #{txn.id}")
      else
        Rails.logger.info("posted_txn #{posted_txn.id} not imported")
      end
    end

    def find_existing
      nil
    end

    def find_factory
      applicable_factories =
        TxnImporterFactory.
        where(from_account_id: posted_txn.account.id).
        where("? ~ memo_regexp", posted_txn.memo).
        limit(2)
      return applicable_factories.first if applicable_factories.count == 1
      nil
    end

    def build_txn
      factory = find_factory
      return nil unless factory

      txn = Txn.new(date: posted_txn.sale_date,
                    payee: factory.payee)
      txn.entries << Entry.new(account: posted_txn.account,
                               user: factory.user,
                               amount: (-posted_txn.amount if posted_txn.amount),
                               memo: posted_txn.memo,
                               num: posted_txn.reference_identifier)
      txn.entries << Entry.new(account: factory.to_account,
                               user: factory.user,
                               amount: posted_txn.amount)
      txn
    end

    def link
      return unless txn
      return if posted_txn.txn.present?
      posted_txn.txn = txn
      posted_txn.save!
    end
  end
end
