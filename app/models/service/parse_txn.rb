module Service
  class ParseTxn
    include ActiveModel::Validations

    attr_reader :input, :txn
    
    def initialize(input)
      @input = input
      @txn = parse(clean(tokenize(input)))
    end
    
    def parse(tokens_list)
      txn = Txn.new
      
      if tokens_list.present?
        rest = tokens_list.first

        # num
        num, rest = self.class.extract(rest) do |tok| 
          (/^#?(\d+)$/.match tok).try(:captures).try(:first)
        end
        txn.num = num

        # date
        date, rest = self.class.extract(rest) do |tok| 
          Chronic.parse(tok).try(:to_date)
        end
        txn.date = date
        
        # payee
        txn.payee = Payee.where("name LIKE ?", rest.join('%')).first
        
      end

      entries = 
        tokens_list.drop(1).map do |entry_tokens|
        ParseEntry.new(entry_tokens).entry
      end

      txn
    end

    class ParseEntry
      attr_reader :input, :entry

      def initialize(tokens)
        @input = tokens
        @entry = parse_entry(tokens)
      end

      # :account, user, amount, memo, ::classif
      def parse_entry(tokens)
        entry = Entry.new
        # account
        account, rest = ParseTxn.extract(tokens) do |tok|
          /^:(.+)/.match(tok).try(:captures).try(:first)
        end
        entry.account = Account.where('name LIKE ?', account).first

        amount, rest = ParseTxn.extract(tokens) do |tok|
          m = tok.to_money
          m.zero? ? nil : m
        end
        entry.amount = amount

        entry
      end
    end

    def clean(tokens_list)
      tokens_list.reject(&:empty?).map { |l| l.reject(&:blank?) }
    end

    def tokenize(input)
      input.split(/\n/).map { |l| l.split(/\s+/) }
    end

    def self.extract(tokens)
      detected, rest = tokens.partition do |e|
        yield(e)
      end
      [yield(detected.first), rest]
    end
  end
end
