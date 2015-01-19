class Account < ActiveRecord::Base
  include HasEntered

  self.table_name = 'account'

  attr_accessible :acct_type, :name, :number, :description, :opened_on, :closed, :closed_on

  has_many :statements, foreign_key: 'acct_id'

  # validates :acct_type, :inclusion 
end
