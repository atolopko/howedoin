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

        # "#num"
        detected, rest = rest.partition do |tok|
          m = /^#?(\d+)$/.match tok
        end
        txn.num = (/^#?(\d+)$/.match detected.first).try(:captures).try(:first)

        # date
        detected, rest = rest.partition do |tok|
          Chronic.parse(tok)
        end
        txn.date = Chronic.parse(detected.first).try(:to_date)

        # :account, user, amount, memo, ::classif
      end
      
      txn
    end

    def clean(tokens_list)
      tokens_list.reject(&:empty?).map { |l| l.reject(&:blank?) }
    end

    def tokenize(input)
      input.split(/\n/).map { |l| l.split(/\s+/) }
    end

    # def self.detect_and_clear(tokens)
    #   extracted = nil
    #   detected, rest = tokens.partition do |e|
    #     v = yield(e)
    #     e
    #   end
    #   extracted, rest
    # end
  end
end
