require 'spec_helper'

describe Txn do

  describe "initialization" do
    it "sets on #entered on create" do
      expect(create(:txn).entered).to_not be_nil
    end
  end

  describe "#dup" do
    let(:t1) { create(:txn) }

    it "copies payee" do t1.dup.payee == t1.payee end
    it "copies date" do t1.dup.date == t1.date end

    it "updates #entered attribute" do 
      t1
      sleep 0.1 # TODO: use timecop
      expect(t1.dup.entered).to be > t1.entered
    end

    it "create same number of entries" do
      expect(t1.dup.entries.size).to eq 2
    end

    it "creates new entries" do
      t1.dup.entries.zip(t1.entries).each { |e| 
        expect(e[0].id).to_not eq e[1].id
      }
    end

    [:user, :amount, :memo].each do |attr|
      it "deep copies entry##{attr}" do
        t1.dup.entries.zip(t1.entries).each { |e| 
          expect(e[0].read_attribute(attr)).to eq e[1].read_attribute(attr)
        }
      end
    end
  end

  describe "#amount" do
    let(:txn) { FactoryGirl.create(:txn, amount: -19.99) }

    it "sums the entries that are assets or liabilities" do
      txn.entries << FactoryGirl.create(:entry, account: FactoryGirl.create(:account, :liability), amount: -0.01)
      txn.entries << FactoryGirl.create(:entry, account: FactoryGirl.create(:account, :income), amount: 0.01)
      expect(txn.amount).to eq -20.00
    end
  end

  describe "#pretty_print" do
    it "returns a human readable string" do
      skip "not yet implemented"
    end

    it "shows '<none>' for missing payee" do
      skip "not yet implemented"
    end
  end

end
