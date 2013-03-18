class Entry < ActiveRecord::Base
  self.table_name = 'entry'

  belongs_to :txn, primary_key: 'trans_id'
  belongs_to :account, foreign_key: 'acct_id', readonly: true
end
