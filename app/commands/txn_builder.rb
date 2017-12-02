class TxnBuilder

  def initialize
    @t = Txn.new
    set_defaults
  end

  def create
    raise "Already created Txn with this TxnBuilder" if @locked
    validate
    build_entry
    add_balancing_entry
    @t.save!
    @locked = true
    @t
  end

  def on(date)
    @t.date = Date.parse(date)
    self
  end

  def paying(payee)
    @t.payee = resolve_model(payee, Payee) do
      Payee.create!(name: payee)
    end
    self
  end

  def paid_by(user)
    @paid_by = resolve_model(user, User, :nickname)
    self
  end

  def using(account)
    @from = resolve_model(account, Account)
    self
  end
 
  def num(num)
    @num = num
    self
  end

  def buying(account, memo = nil)
    @to = resolve_model(account, Account)
    @memo = memo
    self
  end

  def by(user)
    @user = resolve_model(user, User, :nickname)
    self
  end

  def costing(amount)
    @amount = BigDecimal.new(amount)
    self
  end

  def build_entry
    # if all required fields are missing, avoid creating an empty txn
    return self if (@to || @amount || @memo).nil?
    validate
    @t.entries.build(account: @to, user: @user, amount: @amount, memo: @memo)
    @to = @amount = @memo = nil
    self
  end

  alias_method :also, :build_entry
  alias_method :spending, :costing


  def resolve_model(match_value, type, attr = :name)
    if block_given?
      self.class.resolve_model(match_value, type, attr) { yield }
    else
      self.class.resolve_model(match_value, type, attr)
    end
  end

  def self.resolve_model(match_value, type, attr = :name)
    return nil if match_value.blank?
    return match_value if match_value.kind_of? type
    if match_value.kind_of? String
      # TODO: better way to do wildcard matching naturally in Rails?
      res = type.where("#{attr.to_s} ilike ?", match_value).limit(2)
      if res.present?
        raise "Ambiguous #{type} where #{attr}='#{match_value}'" if res.size > 1
        return res.first
      end
    end
    res = type.find(match_value) if match_value.kind_of? Fixnum
    return res if res.present?
    if block_given?
      yield
    else
      raise "No such #{type} where #{attr}='#{match_value}' (#{match_value.class})"
    end
  end


  private

  def add_balancing_entry
    total = @t.entries.reduce(0) { |t,e| t += e.amount }
    user = @paid_by || User.payment_default || @user
    @t.entries.build(account: @from, num: @num, user: user, amount: -total)
  end

  def set_defaults
    @from ||= Account.payment_default
    @t.date ||= Date.today
  end

  def validate
    missing = []
    missing << "amount ('costing')" unless @amount
    missing << "from account ('using')" unless @from
    missing << "to account ('buying')" unless @to
    raise "Cannot create Txn, missing #{missing.join(', ')}" if missing.present?
  end

end
