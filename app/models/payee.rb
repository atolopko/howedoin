class Payee < ActiveRecord::Base
  self.table_name = 'payee'

  has_many :txns
end
