require 'spec_helper'

module Transactions
  describe Importer do

    let(:pt) { create(:posted_transaction) }
    let(:importer) { Importer.new(pt) }

    describe "PostedTransaction is already linked to a Txn" do
      let!(:pt) { create(:posted_transaction,
                         txn: create(:txn)) }

      it "does not create a new Txn" do
        expect { importer.import }.not_to change { Txn.count }
      end

      it "does not change link" do
        expect { importer.import }.not_to change { pt.txn }
      end
    end

    describe "matching Txn exists" do
      it "links PostedTransaction to existing Txn" do
      end

      it "does not create a new PostedTransaction" do
      end
    end

    describe "no matching Txn exists" do
      before do
        importer.import
      end

      it "creates a new Txn" do
        expect(importer.txn).to be_present
      end

      it "persists the new Txn" do
        expect(importer.txn).to be_persisted
      end

      it "links new Txn to PostedTransaction" do
        expect(pt.reload.txn).to eq importer.txn
      end
    end
  end
end

