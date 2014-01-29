class PostedTransaction < ActiveRecord::Base
  attr_accessible :account, :amount

  belongs_to :account, primary_key: 'acct_id', foreign_key: 'account_id'
  belongs_to :txn, primary_key: 'trans_id', foreign_key: 'txn_id'

  validates :account, presence: true
  validates :txn, presence: true#, uniqueness: true
  validates :amount, presence: true, numericality: true
  validates :reference_identifier, uniqueness: true, allow_nil: true
  validate :unique_data

  def matching
    PostedTransaction.
      where(sale_date: sale_date,
            post_date: post_date,
            amount: amount,
            type_identifier: type_identifier,
            category: category,
            memo: memo,
            person: person).
      where(account_id: account.id).
      first
  end

  class MultipleMatchingTxns < StandardError
  end

  # Attempts to find a matching Txn, comparing sale_date, account, and amount
  def find_matching_txn
    return txn if txn
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

  def unique_data
    if matching.present?
      errors[:data] = "non-unique data"
    end
  end

end
