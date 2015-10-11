module Transactions
  class Importer

    def self.import_all
      PostedTransaction.transaction do
        unimported_posted_txns.each do |posted_txn|
          Importer.new(posted_txn).import
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
      return if @txn # Importer object already used

      if posted_txn.txn
        Rails.logger.info("posted_txn #{posted_txn.id} => txn #{posted_txn.txn.id} (previously imported)")
      elsif (@txn = posted_txn.find_matching_txn)
        link
        Rails.logger.info("posted_txn #{posted_txn.id} => existing txn #{@txn.id}")
      elsif (@txn = build_txn)
        link
        Rails.logger.info("posted_txn #{posted_txn.id} => new txn #{@txn.id}")
      else
        Rails.logger.info("posted_txn #{posted_txn.id} not imported")
      end
    end

    def find_factory
      applicable_factories =
        TxnImporterFactory.
        where(from_account_id: posted_txn.account.id).
        where("min_amount is null or ? >= min_amount", posted_txn.amount).
        where("max_amount is null or ? <= max_amount", posted_txn.amount).
        where("? ~ memo_regexp", posted_txn.memo).
        limit(2)
      if applicable_factories.count == 1
        factory = applicable_factories.first
        Rails.logger.debug("using factory #{factory.id}")
        factory
      end
    end

    def build_txn
      factory = find_factory
      return nil unless factory

      @txn = Txn.new(date: posted_txn.sale_date || posted_txn.post_date,
                     payee: factory.payee)
      @txn.entries << Entry.new(account: posted_txn.account,
                                user: factory.user,
                                amount: (-posted_txn.amount if posted_txn.amount),
                                memo: posted_txn.memo,
                                num: posted_txn.reference_identifier)
      @txn.entries << Entry.new(account: factory.to_account,
                                user: factory.user,
                                amount: posted_txn.amount)
      @txn.save!
      @txn
    end

    def link
      return unless @txn
      return if posted_txn.txn.present?
      posted_txn.txn = @txn
      posted_txn.save!
    end
  end
end
