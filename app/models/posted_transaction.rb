class PostedTransaction < ActiveRecord::Base
  attr_accessible :account, :amount

  belongs_to :account, primary_key: 'acct_id', foreign_key: 'account_id'
  belongs_to :txn, primary_key: 'trans_id', foreign_key: 'txn_id'

  validates :account, presence: true
  # validates :txn, presence: true, uniqueness: true
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

  # # Attempts to find a matching Txn, based upon heuristics. If no
  # # found, creates a new Txn using a PostedTransactionNewTxnTemplate
  # def find_or_create_txn
  # end

  # def find_matching_txn
  # end

  # def find_matching_new_txn_template
  # end

  # def create_new_txn_from_template(new_txn_template)
  # end

  def unique_data
    if matching.present?
      errors[:data] = "non-unique data"
    end
  end

end
