require 'spec_helper'

describe "txns/index" do
  before(:each) do
    assign(:txns, [
      stub_model(Txn),
      stub_model(Txn)
    ])
  end

  it "renders a list of txns" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
