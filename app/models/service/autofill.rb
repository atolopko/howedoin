module Service
  class Autofill
    include ActiveModel::Validations
    
    #    attr_accessible :payee, :date
    
    def self.from_last_payee_txn(payee_name, date)
      payees = Payee.where('name ILIKE ?', payee_name)
      if payees.size == 0
        raise "payee not found for name #{payee_name}"
      elsif payees.size > 1
        raise "ambigous payee name"
      else
        last_txn = payees.first.txns.order('date').last
        if last_txn
          new_txn = last_txn.dup
          new_txn.date = date
          new_txn.save!
          new_txn
        end
      end
    end

  end
end
