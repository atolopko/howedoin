module Service
  class ParseTxn
    include ActiveModel::Validations

    attr_reader :input, :txn
    
    def initialize(input)
      @input = input
      @txn = parse(clean(tokenize(input)))
    end
    
    def parse(tokens)
      txn = Txn.new
      
      if tokens.present?
        txn.date = tokens.first.detect { |tok| Chronic.parse(tok) }.try(:to_date)
        # ^date, >payee, #num
        # :account, user, amount, memo, ::classif
      end
      
      txn
    end

    def clean(tokens)
      tokens.reject(&:empty?).map { |l| l.reject(&:blank?) }
    end

    def tokenize(input)
      input.split(/\n/).map { |l| l.split(/\s+/) }
    end

  end
end
