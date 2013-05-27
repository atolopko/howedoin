module Service
  class ParseTxn
    include ActiveModel::Validations

    attr_reader :input, :txn
    
    def initialize(input)
      @input = input || ""
      @txn = parse
    end
    
    def parse
      lines = @input.strip.split(/[\n,;]/)
      parser = LineParser.new(lines.first)

      txn = Txn.new

      # num
      num = parser.extract(/#(\d+)\b/)
      txn.num = num if num.present?

      # date
      date = parser.extract(/\d+[-\/]\d+(?:[-\/]\d+)?/) do |c| 
        Chronic.parse(c).try(:to_date)
      end
      txn.date = date
      
      # payee
      txn.payee = parser.extract(/.*/) do |payee_name|
        Payee.where("name LIKE ?", "%#{payee_name.strip}%").first
      end
      
      txn.entries = lines.drop(1).map do |line|
        ParseEntry.new(line).entry
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
      def parse_entry(line)
        entry = Entry.new
        parser = LineParser.new(line)

        # classification
        # classification, rest = parser.extract(tokens) do |tok|
        #   /^::(.+)/.match(tok).try(:captures).try(:first)
        # end
        # entry.account = Classification.where('name LIKE ?', account).first

        # amount
        entry.amount = parser.extract(/-?\$[0-9.,]+\b/) { |s| s.to_money } || 0.to_money

        # user
        entry.user = parser.extract(/\b[a-z]{4}\b/) do |u|
          User.where(nickname: u).first
        end

        # account
        entry.account = parser.extract(/.*/) do |account_name|
          Account.where('name LIKE ?', "%#{account_name.strip}%").first
        end

        entry
      end
    end

    class LineParser
      def initialize(line)
        @line = (line || "").clone
      end

      # Removes regex-matching substring from line and returns
      # capture(s) of the regex
      def extract(regex)
        extracted = @line.slice!(regex)
        if extracted
          match = extracted.match(regex)
          if match
            result = match.captures.empty? ? match.string : 
              match.captures.size == 1 ? match.captures[0] : match.captures
            block_given? ? yield(result) : result
          end
        end
      end
    end
  end
end
