require 'spec_helper'

describe TxnBuilder do
  let!(:u) { FactoryGirl.create(:user, fullname: 'me', nickname: 'me') }
  let!(:p) { FactoryGirl.create(:payee, name: 'market') }
  let!(:a1) { FactoryGirl.create(:account, :asset, name: 'bank') }
  let!(:a2) { FactoryGirl.create(:account, :expense, name: 'food') }

  def assert_matches(t)
    expect(t.payee).to eq p
    expect(t.date).to eq Date.new(2014, 11, 2)
    expect(t.entries[0].account).to eq a1
    expect(t.entries[0].amount.to_s).to eq '-11.01'
    expect(t.entries[0].user).to eq u
    expect(t.entries[1].account).to eq a2
    expect(t.entries[1].amount.to_s).to eq '11.01'
    expect(t.entries[1].user).to eq u
  end
  
  it "creates a Txn using string identifiers" do
    assert_matches TxnBuilder.new.
      on('2014-11-02').
      by('me').
      paying('market').
      using('bank').
      buying('food').
      costing('11.01').
      create
  end

  it "creates a Txn using string wildcard identifiers" do
    assert_matches TxnBuilder.new.
      on('2014-11-02').
      by('m%').
      paying('MARK%').
      using('b%k').
      buying('%ood').
      costing('11.01').
      create
  end

  it "creates Txn using primary key identifiers" do
    assert_matches TxnBuilder.new.
      on('2014-11-02').
      by(u.id).
      paying(p.id).
      using(a1.id).
      buying(a2.id).
      costing('11.01').
      create
  end

  it "creates Txn using object identifiers" do
    assert_matches TxnBuilder.new.
      on('2014-11-02').
      by(u).
      paying(p).
      using(a1).
      buying(a2).
      costing('11.01').
      create
  end
end
