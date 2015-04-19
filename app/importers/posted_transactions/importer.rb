module PostedTransactions
  class Importer
    attr_accessor :statement, :imported, :errors

    def initialize(account_name, statement_date, ending_balance)
      @account = Account.where("name like ?", account_name).last!
      @statement_date = statement_date
      @ending_balance = ending_balance
    end

    def import(posted_txns, abort_on_error: true)
      @imported = []
      @errors = []
      PostedTransaction.transaction do
        @statement = @account.statements.create!(stmt_date: @statement_date,
                                                 balance: @ending_balance)
        posted_txns.each do |pt|
          begin
            raise "PostedTransaction expected to be not persisted" if pt.persisted?
            pt.account = @statement.account
            pt.statement = @statement
            if pt.save
              @imported << pt
            else
              @errors << [pt, pt.errors.full_messages.join(", ")]
            end
          rescue StandardError => e
            @errors << [pt, e.to_s]
          end
        end
        if @errors.present? && abort_on_error
          @imported.clear
          raise ActiveRecord::Rollback, "import errors"
        end
      end
      @imported.count
    end

    def format_errors
      @errors.map { |data, errors| "#{errors}: #{data}" }.join("\n")
    end

    def errors?
      @errors.present?
    end
  end
end
