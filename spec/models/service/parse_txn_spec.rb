require 'spec_helper'

module Service
  describe ParseTxn do

    describe "LineParser#extract" do
      let(:input) { "a b c" }
      let(:parser) { ParseTxn::LineParser.new(input) }

      it "does not modify passed in string" do
        parser.extract(/b/)
        expect(input).to eq "a b c"
      end

      it "#extract removes matching substring from line" do
        expect(parser.extract(/b/)).to eq 'b'
        expect(parser.extract(/b/)).to be_nil
      end

      it "#extract can be called safely is line is empty" do
        expect(ParseTxn::LineParser.new("").extract(/b/)).to be_nil
      end

      it "#extract passes matching data to block" do
        expect(parser.extract(/b/) { |c| c.upcase }).to eq 'B'
      end

      it "#extract returns captures as array if more than one capture" do
        expect(parser.extract(/a (.) (.)/)).to eq ['b', 'c']
      end

      it "#extract passes captures to block as array if more than one capture" do
        r = parser.extract(/a (.) (.)/) { |c| c.map(&:upcase) }
        expect(r).to eq ['B', 'C']
      end

      it "#extract returns captures as string if only 1 capture" do
        expect(parser.extract(/(b)/)).to eq 'b'
      end

      it "returns nil if no match found" do
        expect(parser.extract(/d/)).to be_nil
      end

      it "does not call block if no match found" do
        expect(parser.extract(/d/) { |e| 'x' }).to_not eq 'x'
      end
    end

    it "#txn should return a Txn" do
      expect(ParseTxn.new("").txn).to be_a_kind_of Txn 
    end
     
    describe "txn line" do
      ["2012-03-18", "#14", "The Bike Shop", " "].permutation.map { |s| s.join ' ' }.each do |input|
        let!(:payee) { FactoryGirl.create(:payee, name: "The Bike Shop") }
        let(:txn) { ParseTxn.new(input).txn }

        it "parses date located in '#{input}'" do
          expect(txn.date).to eq Date.new(2012, 3, 18)
        end

        it "parses payee located in '#{input}'" do
          expect(txn.payee.name).to eq "The Bike Shop"
        end

        it "parses num located in '#{input}'" do
          expect(txn.num).to eq "14"
        end
      end

      describe "parses payee name substring" do
        let!(:payee) { FactoryGirl.create(:payee, name: "The Bike Shop") }
        let(:txn) { ParseTxn.new("2012-03-18 #14 Bike Shop").txn }

        it "parses payee" do
          expect(txn.payee.name).to eq "The Bike Shop"
        end
      end

      describe "ignores leading empty lines" do
        let!(:payee) { FactoryGirl.create(:payee, name: "The Bike Shop") }
        let(:txn) { ParseTxn.new("\n\n2012-03-18").txn }

        it "parses date" do
          expect(txn.date).to eq Date.new(2012, 3, 18)
        end
      end
      
      describe "missing date" do
        let(:txn) { ParseTxn.new("#14 The Bike Shop").txn }
        
        it "returns a Txn without a date value" do
          expect(txn.date).to be_nil
        end
        
        it "parses payee" do
          expect(txn.payee.name).to eq "The Bike Shop"
        end
        
        it "parses num" do
          expect(txn.num).to eq "14"
        end
      end

      describe "missing num" do
        let(:txn) { ParseTxn.new("2012-03-18 The Bike Shop").txn }
        
        it "returns a Txn without a num" do
          expect(txn.num).to be_nil
        end
        
        it "parses payee" do
          expect(txn.payee.name).to eq "The Bike Shop"
        end
        
        it "parses date" do
          expect(txn.date).to eq Date.new(2012, 3, 18)
        end
      end

    end

    describe "#parse_entry" do
      ["$1.01",
       "$1.01 #Account user",
       "Account $1.01 user",
       "Account user $1.01"].each do |input|
        it "parses amount from #{input}" do
          expect(ParseTxn::ParseEntry.new(input).entry.amount).to eq Money.new(101).to_d
        end
      end
      
      it "parses missing amount as zero" do
        expect(ParseTxn::ParseEntry.new("Account user").entry.amount).to eq 0
      end

      it "parses zero amount as zero" do
        expect(ParseTxn::ParseEntry.new("Account $0.00 user").entry.amount).to eq 0
      end

      it "parses negative amount" do
        expect(ParseTxn::ParseEntry.new("Account -$1.00 user").entry.amount).to eq -1.0
      end

      describe "account" do
        let!(:account) { FactoryGirl.create(:account, name: "Major:Minor Stuff") }

        it "parses fully qualified account name" do
          expect(ParseTxn::ParseEntry.new("Major:Minor").entry.account).to eq account
        end

        it "parses account name with whitespace in name" do
          expect(ParseTxn::ParseEntry.new("Major:Minor Stuff").entry.account).to eq account
        end

        it "parses partially qualified account name" do
          expect(ParseTxn::ParseEntry.new(":Minor").entry.account).to eq account
        end

        it "parses partially qualified account name substring" do
          expect(ParseTxn::ParseEntry.new(":Minor").entry.account).to eq account
        end
      end

      ["Account", "$0.00", "usra"].permutation.map { |s| s.join ' ' }.each do |input|
        let!(:user_a) { FactoryGirl.create(:user, nickname: "usra", fullname: "User A") }
        let!(:user_b) { FactoryGirl.create(:user, nickname: "usrb", fullname: "User B") }
        it "parses user" do
          expect(ParseTxn::ParseEntry.new(input).entry.user).to eq user_a
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
          expect(txn.date).to eq Date.new(2012, 3, 18)
        end

        it "sets num" do
          expect(txn.num).to eq "101"
        end

        it "sets payee" do
          expect(txn.payee).to eq payee
        end

        it "create entries" do
          expect(txn.entries.size).to eq 2
        end

        it "sets first entry account" do
          expect(txn.entries[0].account).to eq cash_account
        end

        it "sets second entry account" do
          expect(txn.entries[1].account).to eq cycling_account
        end

        it "sets first entry amount" do
          expect(txn.entries[0].amount).to eq -5.0
        end

        it "sets second entry amount" do
          expect(txn.entries[1].amount).to eq 5.0
        end

        it "sets first entry user" do
          expect(txn.entries[0].user).to eq user
        end

        it "sets second entry user" do
          expect(txn.entries[1].user).to eq user
        end
      end
    end
  end
end
