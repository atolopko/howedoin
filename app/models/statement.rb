class Statement < ActiveRecord::Base
  include HasEntered

  self.table_name = 'bankstatement'

  attr_accessible :stmt_date, :balance

  belongs_to :account, foreign_key: 'acct_id', readonly: true

  validate :account, presence: true
  validate :account, unique: { scope: :stmt_date }

end
