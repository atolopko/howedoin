require 'spec_helper'

module Service
  describe ParseTxn do

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
    end

    describe "no date" do
      let(:txn) { ParseTxn.new("#14 The Bike Shop").txn }

      it "should return a Txn without a date value" do
        txn.date.should be_nil
      end
    end
  end
end
