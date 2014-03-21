module Service
  class DefaultTxnFactory
    def initialize(to_account = nil, user = nil, payee = nil)
      @to_account = to_account || Account.where(name: 'unassigned', acct_type: 'expense').first
      @user = user || User.first
      @payee = payee
    end

    def applies?(pt)
      pt.sale_date.present? && pt.account.present? && pt.amount.present?
    end

    def build(pt)
      txn = Txn.new(date: pt.sale_date,
                    payee: @payee)
      txn.entries << Entry.new(account: pt.account,
                               user: @user,
                               amount: (-pt.amount if pt.amount),
                               memo: pt.memo,
                               num: pt.reference_identifier)
      txn.entries << Entry.new(account: @to_account,
                               user: @user,
                               amount: pt.amount)
      txn
    end
  end
end
