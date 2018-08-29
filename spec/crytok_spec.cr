require "./spec_helper"
require "../src/langs/en"
describe CryTok do
  # TODO: Write tests
  tok = CryTok.build_en
  it "I'm fine" do
    tok.tokens("I'm fine").should eq(["I", "'m", "fine"])
  end

  # it "How are you.fine" do
  #   tok.tokens("How are you.fine").should eq(["How", "are", "you", ".", "fine"])
  # end

  # it "Chen'll...." do
  #   tok.tokens("Chen'll....").should eq(["Chen", "'ll", "...."])
  # end

  # it "Can't..." do
  #   tok.tokens("Can't...").should eq(["Can", "'t", "...."])
  # end

  # it "\"Haha\"" do
  #   tok.tokens("\"Haha\"").should eq(["\"", "Haha", "\""])
  # end

  # it "A-B's " do
  #   tok.tokens("A-B's ").should eq(["A-B", "'s"])
  # end
  # it "A我's (utf8)" do
  #   tok.tokens("A我's ").should eq(["A我", "'s"])
  # end
end
