module Transactions
  class Importer

    def self.import_all(factory: nil, statement: nil)
      result = Hash.new { |h,k| h[k] = [] }
      PostedTransaction.transaction do
        unimported = unimported_posted_txns(statement)
        Rails.logger.info("found #{unimported.count} unimported posted transaction(s)")
        unimported.each do |posted_txn|
          status = Importer.new(posted_txn, factory).import
          result[status] << posted_txn
        end
      end
      result
    end

    def self.unimported_posted_txns(statement = nil)
      unimported = PostedTransaction.where(txn_id: nil)
      unimported = unimported.where(stmt_id: statement.id) if statement
      unimported
    end

    def self.link_posted_transaction_to_txn(posted_transaction_id, txn_id)
      PostedTransaction.transaction do
        new(PostedTransaction.find(posted_transaction_id)).
          link_posted_transaction_to_txn(Txn.find(txn_id))
      end
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
        link_posted_transaction_to_txn(@txn)
        Rails.logger.info("posted_txn #{posted_txn.id} => existing txn #{@txn.id}")
        :linked_to_existing
      elsif @txn = build_txn
        Rails.logger.info("posted_txn #{posted_txn.id} => new txn #{@txn.id}")
        :created
      else
        Rails.logger.info("posted_txn #{posted_txn.id} not imported")
        :not_imported
      end
    rescue MultipleMatchingTxnsError => e
      Rails.logger.info("posted_txn #{posted_txn.id} matches multiple existings txns: #{e}")
      :matches_multiple_existing
    end

    def find_factory
      applicable_factories =
        TxnImporterFactory.
        where(from_account_id: posted_txn.account.id).
        where("min_amount is null or ? >= min_amount", posted_txn.amount).
        where("max_amount is null or ? <= max_amount", posted_txn.amount).
        where("min_date is null or ? >= min_date", posted_txn.post_date || posted_txn.sale_date).
        where("max_date is null or ? < max_date", posted_txn.post_date || posted_txn.sale_date).
        where("? ~* memo_regexp", posted_txn.memo).
        limit(2)
      if applicable_factories.count > 1
        Rails.logger.warn("found multiple factories: #{applicable_factories.map(&:id).join(',')}")
      end
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
      from_amount = posted_txn.account.stmt_amounts_negated? ? -from_amount : from_amount
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
      @txn.save!
      link_posted_transaction_to_txn(@txn)
      return @txn
    end

    def link_posted_transaction_to_txn(txn)
      return unless txn
      return if posted_txn.txn.present?
      posted_txn.txn = txn
      posted_txn.save!
      link_entry_to_bank_statement(txn)
    end

    def link_entry_to_bank_statement(txn)
      return unless txn
      txn.entries.where(acct_id: posted_txn.account.acct_id).each do |entry|
        entry.statement = posted_txn.statement
        entry.save!
      end
    end
  end
end
