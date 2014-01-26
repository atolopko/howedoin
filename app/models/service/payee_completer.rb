module Service
  class PayeeCompleter
    def initialize(query)
      # TODO: if input contains capital letters, do not search case-insenitively
      @payees = Payee.where("name ilike :query or memo ilike :query", query: "%#{query}%")
    end

    def candidates
      @payees.sort { |p1,p2| rank(p1, p2) }.map { |p| "#{p.name} (#{age(p)}, #{p.txns.count}, #{p.memo})" }
    end

    def complete
      @payees.first
    end

    def age(payee)
      ((Time.now - (payee.txns.last.try(:entered) || Time.new(0))) / 1.year).truncate
    end

    def rank(payee1, payee2)
      result = age(payee1) <=> age(payee2)
      result = -1 * (payee1.txns.count <=> payee2.txns.count) if result == 0
      result
    end
  end
end
