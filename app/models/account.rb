class Account < ActiveRecord::Base
  self.table_name = 'account'
  attr_accessible :name, :number, :description, :opened_on, :closed, :closed_on
end
