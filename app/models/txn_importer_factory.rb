class TxnImporterFactory < ActiveRecord::Base
  attr_protected

  belongs_to :user
  belongs_to :payee
  belongs_to :from_account, class_name: 'Account'
  belongs_to :to_account, class_name: 'Account'

  validates :memo_regexp, :user, :from_account, :to_account, presence: true

  # Creates TxnImporterFactory where attributes for associated models
  # may be may a model instance, id, or an SQL wildcard string
  # matching the name of a unique instance
  def self.smart_create(attrs)
    to_account = TxnBuilder.resolve_model(attrs[:to_account], Account)
    from_account = TxnBuilder.resolve_model(attrs[:from_account], Account)
    payee = TxnBuilder.resolve_model(attrs[:payee], Payee)
    user = TxnBuilder.resolve_model(attrs[:user], User, :nickname)
    TxnImporterFactory.
      create(memo_regexp: attrs[:memo_regexp],
          min_amount: attrs[:min_amount],
          max_amount: attrs[:max_amount],
          to_account: to_account,
          from_account: from_account,
          user: user,
          payee: payee)
  end

end

