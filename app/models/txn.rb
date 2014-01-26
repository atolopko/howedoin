class Txn < ActiveRecord::Base
  self.table_name = 'transaction'

  attr_accessible :date, :payee

  attr_accessor :num

  validates :date, presence: true

  before_create :set_entered

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

  private

  def set_entered
    self.entered = Time.now if new_record?
  end
end
