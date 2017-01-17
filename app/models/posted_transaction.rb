class PostedTransaction < ActiveRecord::Base
  attr_accessible :account, :statement, :amount, :type_identifier, :sale_date, :post_date, :txn_importer_factory

  belongs_to :account, primary_key: 'acct_id', foreign_key: 'account_id'
  belongs_to :statement, primary_key: 'stmt_id', foreign_key: 'stmt_id'
  belongs_to :txn, primary_key: 'trans_id', foreign_key: 'txn_id'
  belongs_to :txn_importer_factory

  validates :account, presence: true
  validates :statement, presence: true
  validates :amount, presence: true, numericality: true
  validates :reference_identifier, uniqueness: true, allow_nil: true
  validates :sale_date, presence: true, unless: :post_date?
  validates :post_date, presence: true, unless: :sale_date?

  # Attempts to find a matching Txn, comparing sale_date, account, and amount
  def find_matching_txn
    candidates =
      Txn.
      where('NOT EXISTS (select 1 from posted_transactions pt where pt.txn_id = transaction.trans_id and pt.account_id = ?)', account.id).
      joins(:entries).
      where(entry: { acct_id: account.id }).
      where("date between (date :pt_date - interval '7 days') and (date :pt_date)",
            pt_date: sale_date || post_date).
      group('transaction.trans_id').
      having('sum(amount) = ?', amount)
    candidates = candidates.all
    if candidates.count > 1
      raise MultipleMatchingTxnsError, candidates.map(&:id).sort.join(", ") 
    else
      candidates.first
    end
  end

  def to_s
    "[#{self.class.name}: #{self.attributes.map { |k,v| k + '=' + v.to_s }.join(', ')}"
  end

end
