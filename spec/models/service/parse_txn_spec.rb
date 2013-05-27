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
     
    describe "txn line" do
      ["2012-03-18", "#14", "The Bike Shop", " "].permutation.map { |s| s.join ' ' }.each do |input|
        let!(:payee) { FactoryGirl.create(:payee, name: "The Bike Shop") }
        let(:txn) { ParseTxn.new(input).txn }

        it "parses date located in '#{input}'" do
          txn.date.should == Date.new(2012, 3, 18)
        end

        it "parses payee located in '#{input}'" do
          txn.payee.name.should == "The Bike Shop"
        end

        it "parses num located in '#{input}'" do
          txn.num.should == "14"
        end
      end

      describe "parses payee name substring" do
        let!(:payee) { FactoryGirl.create(:payee, name: "The Bike Shop") }
        let(:txn) { ParseTxn.new("2012-03-18 #14 Bike Shop").txn }

        it "parses payee" do
          txn.payee.name.should == "The Bike Shop"
        end
      end

      describe "ignores leading empty lines" do
        let!(:payee) { FactoryGirl.create(:payee, name: "The Bike Shop") }
        let(:txn) { ParseTxn.new("\n\n2012-03-18").txn }

        it "parses date" do
          txn.date.should == Date.new(2012, 3, 18)
        end
      end
      
      describe "missing date" do
        let(:txn) { ParseTxn.new("#14 The Bike Shop").txn }
        
        it "returns a Txn without a date value" do
          txn.date.should be_nil
        end
        
        it "parses payee" do
          txn.payee.name.should == "The Bike Shop"
        end
        
        it "parses num" do
          txn.num.should == "14"
        end
      end

      describe "missing num" do
        let(:txn) { ParseTxn.new("2012-03-18 The Bike Shop").txn }
        
        it "returns a Txn without a num" do
          txn.num.should be_nil
        end
        
        it "parses payee" do
          txn.payee.name.should == "The Bike Shop"
        end
        
        it "parses date" do
          txn.date.should == Date.new(2012, 3, 18)
        end
      end

    end

    describe "#parse_entry" do
      ["$1.01",
       "$1.01 #Account user",
       "Account $1.01 user",
       "Account user $1.01"].each do |input|
        it "parses amount from #{input}" do
          ParseTxn::ParseEntry.new(input).entry.amount.should == Money.new(101).to_d
        end
      end
      
      it "parses missing amount as zero" do
        ParseTxn::ParseEntry.new("Account user").entry.amount.should == 0
      end

      it "parses zero amount as zero" do
        ParseTxn::ParseEntry.new("Account $0.00 user").entry.amount.should == 0
      end

      it "parses negative amount" do
        ParseTxn::ParseEntry.new("Account -$1.00 user").entry.amount.should == -1.0
      end

      describe "account" do
        let!(:account) { FactoryGirl.create(:account, name: "Major:Minor Stuff") }

        it "parses fully qualified account name" do
          ParseTxn::ParseEntry.new("Major:Minor").entry.account.should == account
        end

        it "parses account name with whitespace in name" do
          ParseTxn::ParseEntry.new("Major:Minor Stuff").entry.account.should == account
        end

        it "parses partially qualified account name" do
          ParseTxn::ParseEntry.new(":Minor").entry.account.should == account
        end

        it "parses partially qualified account name substring" do
          ParseTxn::ParseEntry.new(":Minor").entry.account.should == account
        end
      end

      ["Account", "$0.00", "usra"].permutation.map { |s| s.join ' ' }.each do |input|
        let!(:user_a) { FactoryGirl.create(:user, nickname: "usra", fullname: "User A") }
        let!(:user_b) { FactoryGirl.create(:user, nickname: "usrb", fullname: "User B") }
        it "parses user" do
          ParseTxn::ParseEntry.new(input).entry.user.should == user_a
        end
      end
    end

    ["2012-03-18 #101 The Bike Shop\n  Cash -$5.00 drew\n  Cycling $5.00 drew",
     "2012-03-18 #101 The Bike Shop,Cash -$5.00 drew,  Cycling $5.00 drew",
     "2012-03-18 #101 The Bike Shop; Cash -$5.00 drew,Cycling $5.00 drew\n\n"].each do |input|
      describe "parsing full transaction" do
        let!(:user) { FactoryGirl.create(:user, nickname: "drew", fullname: "Drew Smith") }
        let!(:cash_account) { FactoryGirl.create(:account, name: "Cash", acct_type: "asset") }
        let!(:cycling_account) { FactoryGirl.create(:account, name: "Cycling", acct_type: "expense") }
        let!(:payee) { FactoryGirl.create(:payee, name: "The Bike Shop") }
        let(:txn) { ParseTxn.new(input).txn }

        it "sets date" do
          txn.date.should == Date.new(2012, 3, 18)
        end

        it "sets num" do
          txn.num.should == "101"
        end

        it "sets payee" do
          txn.payee.should == payee
        end

        it "create entries" do
          txn.entries.size.should == 2
        end

        it "sets first entry account" do
          txn.entries[0].account.should == cash_account
        end

        it "sets second entry account" do
          txn.entries[1].account.should == cycling_account
        end

        it "sets first entry amount" do
          txn.entries[0].amount.should == -5.0
        end

        it "sets second entry amount" do
          txn.entries[1].amount.should == 5.0
        end

        it "sets first entry user" do
          txn.entries[0].user.should == user
        end

        it "sets second entry user" do
          txn.entries[1].user.should == user
        end
      end
    end
  end
end
