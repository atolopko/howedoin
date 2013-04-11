require 'spec_helper'

module Service
  describe ParseTxn do

    describe "#extract" do
      it "works" do
        result = ParseTxn.extract(%w{ a b c }) do |e|
          e.upcase if e == 'b'
        end
        result.should == ['B', %w{ a c }]
      end

      it "handles undetected token" do
        result = ParseTxn.extract(%w{ a b c }) do |e|
          e.upcase if e == 'd'
        end
        result.should == [nil, %w{ a b c }]
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
       "2012-03-18 14",
       "14 2012-03-18",
       "The Bike Shop #14",
       "#14 The Bike Shop",
      ].each do |input| 
        it "returns num from #{input}" do
          ParseTxn.new(input).txn.
            num.should == '14'
        end
      end
    end

    describe "#parse_entry" do
      [["$1.01"],
       ["$1.01", ":Account", "user"],
       [":Account", "$1.01", "user"],
       [":Account", "user", "$1.01"]].each do |input|
        it "parses amount" do
          ParseTxn::ParseEntry.new(input).entry.amount.should == Money.new(101).to_d
        end
      end
      
      it "parses missing amount as zero" do
        ParseTxn::ParseEntry.new([":Account", "user"]).entry.amount.should == 0
      end

      it "parses zero amount as zero" do
        ParseTxn::ParseEntry.new([":Account", "$0.00", "user"]).entry.amount.should == 0
      end

      [":Account", "$0.00", "usr1"].permutation.each do |input|
        it "parser user" do
          user1 = FactoryGirl.create(:user, nickname: "usr1", fullname: "User 1")
          FactoryGirl.create(:user, nickname: "usr2", fullname: "User 2")
          ParseTxn::ParseEntry.new(input).entry.user.should == user1
        end
      end

    end
  end
end
