class PostedTransaction < ActiveRecord::Base
  attr_accessible :account, :statement, :amount, :type_identifier, :sale_date, :post_date

  belongs_to :account, primary_key: 'acct_id', foreign_key: 'account_id'
  belongs_to :statement, primary_key: 'stmt_id', foreign_key: 'stmt_id'
  belongs_to :txn, primary_key: 'trans_id', foreign_key: 'txn_id'

  validates :account, presence: true
  validates :statement, presence: true
  validates :txn_id, uniqueness: true, allow_nil: true
  validates :amount, presence: true, numericality: true
  validates :reference_identifier, uniqueness: true, allow_nil: true

  class MultipleMatchingTxns < StandardError
  end

  # Attempts to find a matching Txn, comparing sale_date, account, and amount
  def find_matching_txn
    candidates = Txn.
      where('NOT EXISTS (select 1 from posted_transactions pt where pt.txn_id = transaction.trans_id)').
      where(date: sale_date).joins(:entries).
      where(entry: { acct_id: account.id }).
      group('transaction.trans_id').
      having('sum(amount) = ?', amount).
      all
    if candidates.size > 1
      raise MultipleMatchingTxns, candidates.map(&:id).join(", ") 
    else
      candidates.first
    end
  end

  def to_s
    "[#{self.class.name}: #{self.attributes.map { |k,v| k + '=' + v.to_s }.join(', ')}"
  end

end
