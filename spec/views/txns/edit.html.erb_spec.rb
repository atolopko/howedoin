require 'spec_helper'

describe "txns/edit" do
  before(:each) do
    @txn = assign(:txn, stub_model(Txn))
  end

  it "renders the edit txn form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", txn_path(@txn), "post" do
    end
  end
end
