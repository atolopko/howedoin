require 'csv'

module Importers
  class Parser

    def initialize(posted_txns_csv)
      @posted_txns_csv = posted_txns_csv
      @posted_txns = []
    end

    def posted_txns
      raise NotImplementedError
    end

    def statement_date
      m = @posted_txns_csv.match /(\d{4})-(\d{2})-(\d{2})/
      Date.new(m[1].to_i, m[2].to_i, m[3].to_i) if m
    end
   
    def ending_balance
      nil
    end

    private

    def to_amount(str_amount)
      return nil if str_amount.blank?
      BigDecimal.new(str_amount.gsub(/[$,]/, ''))
    end      

  end
end
