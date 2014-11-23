class Entry < ActiveRecord::Base
  self.table_name = 'entry'

  # attr_accessible :account, :user, :amount, :memo, :num

  attr_readonly :user, :account

  belongs_to :txn, foreign_key: 'trans_id'
  belongs_to :account, foreign_key: 'acct_id'
  belongs_to :user
end
