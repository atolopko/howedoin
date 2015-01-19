class Payee < ActiveRecord::Base
  include HasEntered

  self.table_name = 'payee'

  attr_accessible :name

  has_many :txns
end
