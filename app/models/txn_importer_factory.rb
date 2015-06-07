class TxnImporterFactory < ActiveRecord::Base
  attr_protected

  belongs_to :user
  belongs_to :payee
  belongs_to :from_account, class_name: 'Account'
  belongs_to :to_account, class_name: 'Account'

  validates :memo_regexp, :user, :payee, :from_account, :to_account, presence: true

end

