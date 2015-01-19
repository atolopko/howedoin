class TxnBuilder
  def create
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

end
