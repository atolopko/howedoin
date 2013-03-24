class Account < ActiveRecord::Base
  self.table_name = 'account'

  attr_accessible :acct_type, :name, :number, :description, :opened_on, :closed, :closed_on

  # validates :acct_type, :inclusion 
end
