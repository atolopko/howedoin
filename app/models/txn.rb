class Txn < ActiveRecord::Base
  include HasEntered

  self.table_name = 'transaction'

  attr_accessible :date, :payee

  attr_accessor :num

  validates :date, presence: true

  belongs_to :payee, primary_key: 'payee_id'
  has_many :entries, foreign_key: 'trans_id', autosave: true
  has_one :posted_transaction

  def dup
    new_txn = super
    new_txn.entries = self.entries.map(&:dup)
    new_txn.entered = Time.now
    new_txn
  end

  def payee_name
    payee.name
  end

  def amount
    entries.joins(:account).where(account: { acct_type: ['asset', 'liability'] }).sum(:amount)
  end

  def pretty_print
    "#{date.strftime('%F')} \"#{payee.try(:name) || '<none>'}\" #{amount}\n" +
      entries.map(&:pretty_print).join("\n")
  end
end
