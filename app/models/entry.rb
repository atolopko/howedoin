class Entry < ActiveRecord::Base
  self.table_name = 'entry'

  attr_accessible :account, :user, :amount, :memo, :num, :statement

  belongs_to :txn, foreign_key: 'trans_id'
  belongs_to :account, foreign_key: 'acct_id', readonly: true
  belongs_to :user, readonly: true
  belongs_to :statement, primary_key: 'stmt_id', foreign_key: 'stmt_id'

  def pretty_print
    s = "<#{account.name}> #{amount} [#{user.nickname}]"
    s += "\n\"#{memo}\"" if memo
    s
  end
end
