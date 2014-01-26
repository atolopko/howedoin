class PostedTransaction < ActiveRecord::Base
  attr_accessible :account, :amount

  belongs_to :account

  validates :amount, presence: true, numericality: true
  validates :account, presence: true

end
