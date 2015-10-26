module Transactions
  class Importer

    def self.import_all(factory = nil)
      result = Hash.new { |h,k| h[k] = [] }
      PostedTransaction.transaction do
        unimported_posted_txns.each do |posted_txn|
          status = Importer.new(posted_txn, factory).import
          result[status] << posted_txn
        end
      end
      result
    end

    def self.unimported_posted_txns
      PostedTransaction.where(txn_id: nil)
    end

    attr_accessor :posted_txn, :txn

    def initialize(posted_txn, factory = nil)
      @posted_txn = posted_txn
      @factory = factory
    end

    def import
      return :redundant_call if @txn

      if posted_txn.txn
        Rails.logger.info("posted_txn #{posted_txn.id} => txn #{posted_txn.txn.id} (previously imported)")
        :previously_imported
      elsif (@txn = posted_txn.find_matching_txn)
        link
        Rails.logger.info("posted_txn #{posted_txn.id} => existing txn #{@txn.id}")
        :linked_to_existing
      elsif @txn = build_txn
        Rails.logger.info("posted_txn #{posted_txn.id} => new txn #{@txn.id}")
        :created
      else
        Rails.logger.info("posted_txn #{posted_txn.id} not imported")
        :not_imported
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
        if @factory.nil? || @factory == factory
          Rails.logger.debug("using factory #{factory.id}")
          factory
        end
      end
    end

    def build_txn
      factory = find_factory
      return nil unless factory

      @txn = Txn.new(date: posted_txn.sale_date || posted_txn.post_date,
                     payee: factory.payee)
      from_amount = posted_txn.account.asset_or_liability? ? posted_txn.amount : -posted_txn.amount
      to_amount = -from_amount
      @txn.entries << Entry.new(account: posted_txn.account,
                                user: factory.user,
                                amount: from_amount,
                                memo: posted_txn.memo,
                                num: posted_txn.reference_identifier)
      @txn.entries << Entry.new(account: factory.to_account,
                                user: factory.user,
                                amount: to_amount)
      posted_txn.txn_importer_factory = factory
      link
      @txn.save!
      return @txn
    end

    def link
      return unless @txn
      return if posted_txn.txn.present?
      posted_txn.txn = @txn
      posted_txn.save!
    end
  end
end
