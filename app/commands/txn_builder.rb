class TxnBuilder
  def create
    set_defaults
    validate
    t = Txn.new(date: @date)
    t.payee = @payee
    t.entries.build(account: @from, user: @user, amount: -1 * @amount)
    t.entries.build(account: @to, user: @user, amount: @amount)
    t.save!
    t
  end

  def on(date)
    @date = Date.parse(date)
    self
  end

  def by(user)
    @user = resolve_model(user, User, :nickname)
    self
  end

  def paying(payee)
    @payee = resolve_model(payee, Payee)
    self
  end

  def costing(amount)
    @amount = BigDecimal.new(amount)
    self
  end

  def using(account)
    @from = resolve_model(account, Account)
    self
  end
 
  def buying(account)
    @to = resolve_model(account, Account)
    self
  end

  private

  def resolve_model(match_value, type, attr = :name)
    return match_value if match_value.kind_of? type
    # TODO: better way to do wildcard matching naturally in Rails?
    return type.where("#{attr.to_s} ilike ?", match_value).first! if match_value.kind_of? String
    return type.find(match_value) if match_value.kind_of? Fixnum
    raise "Cannot parse #{type} '#{match_value}' (#{match_value.class})"
  end

  def set_defaults
    @from ||= Account.payment_default
  end

  def validate
    missing = []
    missing << "date ('on')" unless @date
    missing << "user ('by')" unless @user
    missing << "payee ('paying')" unless @payee
    missing << "amount ('costing')" unless @amount
    missing << "from account ('using')" unless @from
    missing << "to account ('buying')" unless @to
    raise "Cannot create Txn, missing #{missing.join(', ')}" if missing.present?
  end

end
