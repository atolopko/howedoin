class Account < ActiveRecord::Base
  include HasEntered

  self.table_name = 'account'

  attr_accessible :acct_type, :name, :number, :description, :opened_on, :closed, :closed_on, :payment_default

  has_many :statements, foreign_key: 'acct_id'

  # validates :acct_type, :inclusion 

  def self.payment_default
    Account.where(payment_default: true).first
  end
end
