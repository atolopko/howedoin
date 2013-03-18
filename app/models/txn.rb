class Txn < ActiveRecord::Base
  self.table_name = 'transaction'

  attr_accessible :date, :payee

  validates :date, presence: true

  before_save :set_entered

  belongs_to :payee, primary_key: 'payee_id'
  has_many :entries, foreign_key: 'trans_id', autosave: true

  private

  def set_entered
    self.entered = Time.now
  end
end
