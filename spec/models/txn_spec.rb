require 'spec_helper'

describe Txn do

  describe "initialization" do
    it "sets on #entered on create" do
      FactoryGirl.create(:txn).entered.should_not be_nil
    end
  end

  describe "#dup" do
    let(:t1) { FactoryGirl.create(:txn) }

    it "copies payee" do t1.dup.payee == t1.payee end
    it "copies date" do t1.dup.date == t1.date end

    it "updates #entered attribute" do 
      t1
      sleep 1 # TODO: use timecop
      t1.dup.entered.should > t1.entered
    end

    it "create same number of entries" do
      t1.dup.entries.size.should == 2
    end

    it "creates new entries" do
      t1.dup.entries.zip(t1.entries).each { |e| 
        e[0].id.should_not == e[1].id
      }
    end

    [:user, :amount, :memo].each do |attr|
      it "deep copies entry##{attr}" do
        t1.dup.entries.zip(t1.entries).each { |e| 
          e[0].read_attribute(attr).should == e[1].read_attribute(attr)
        }
      end
    end
  end

end