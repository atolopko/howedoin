require 'spec_helper'

module Service
  describe ParseTxn do

    describe "LineParser#extract" do
      let(:input) { "a b c" }
      let(:parser) { ParseTxn::LineParser.new(input) }

      it "does not modify passed in string" do
        parser.extract(/b/)
        input.should == "a b c"
      end

      it "#extract removes matching substring from line" do
        parser.extract(/b/).should == 'b'
        parser.extract(/b/).should be_nil
      end

      it "#extract can be called safely is line is empty" do
        ParseTxn::LineParser.new("").extract(/b/).should be_nil
      end

      it "#extract passes matching data to block" do
        parser.extract(/b/) { |c| c.upcase }.should == 'B'
      end

      it "#extract returns captures as array if more than one capture" do
        parser.extract(/a (.) (.)/).should == ['b', 'c']
      end

      it "#extract passes captures to block as array if more than one capture" do
        r = parser.extract(/a (.) (.)/) { |c| c.map(&:upcase) }
        r.should == ['B', 'C']
      end

      it "#extract returns captures as string if only 1 capture" do
        parser.extract(/(b)/).should == 'b'
      end

      it "returns nil if no match found" do
        parser.extract(/d/).should be_nil
      end

      it "does not call block if no match found" do
        parser.extract(/d/) { |e| 'x' }.should_not == 'x'
      end
    end

    it "#txn should return a Txn" do
      ParseTxn.new("").txn.should be_a_kind_of Txn 
    end
     
    describe "date" do
      ["2012-03-18 #14 The Bike Shop", 
       "  2012-03-18 #14 The Bike Shop",
       "#14 2012-03-18 The Bike Shop", 
       "#14 The Bike Shop 2012-03-18",
       "  2012-03-18  ",
       "2012-03-18 2012-03-19",
       "\n\n2012-03-18"].each do |input|
        it "parses date located in '#{input}'" do
          ParseTxn.new(input).txn.
            date.should == Date.new(2012, 3, 18)
        end
      end
      
      describe "no date" do
        let(:txn) { ParseTxn.new("#14 The Bike Shop").txn }
        
        it "returns a Txn without a date value" do
          txn.date.should be_nil
        end
      end
    end

    describe "num" do
      ["#14",
       "2012-03-18 #14",
       "#14 2012-03-18",
       "The Bike Shop #14",
       "#14 The Bike Shop"
      ].each do |input| 
        it "returns num from #{input}" do
          ParseTxn.new(input).txn.
            num.should == '14'
        end
      end

      describe "no num" do
        let(:txn) { ParseTxn.new("2012-03-18 The Bike Shop").txn }
        
        it "returns a Txn without a num value" do
          txn.num.should be_nil
        end
      end
    end

    describe "#parse_entry" do
      ["$1.01",
       "$1.01 :Account user",
       ":Account $1.01 user",
       ":Account user $1.01"].each do |input|
        it "parses amount from #{input}" do
          ParseTxn::ParseEntry.new(input).entry.amount.should == Money.new(101).to_d
        end
      end
      
      it "parses missing amount as zero" do
        ParseTxn::ParseEntry.new(":Account user").entry.amount.should == 0
      end

      it "parses zero amount as zero" do
        ParseTxn::ParseEntry.new(":Account $0.00 user").entry.amount.should == 0
      end

      [":Account", "$0.00", "usra"].permutation.map { |s| s.join ' ' }.each do |input|
        let!(:user_a) { FactoryGirl.create(:user, nickname: "usra", fullname: "User A") }
        let!(:user_b) { FactoryGirl.create(:user, nickname: "usrb", fullname: "User B") }
        it "parses user" do
          ParseTxn::ParseEntry.new(input).entry.user.should == user_a
        end
      end

    end
  end
end
