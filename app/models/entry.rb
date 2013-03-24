class Entry < ActiveRecord::Base
  self.table_name = 'entry'

  attr_accessible :account, :user, :amount

  belongs_to :txn, primary_key: 'trans_id'
  belongs_to :account, foreign_key: 'acct_id', readonly: true
  belongs_to :user, readonly: true
end