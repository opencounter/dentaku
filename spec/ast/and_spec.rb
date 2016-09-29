require 'spec_helper'
require 'dentaku/ast/combinators'

require 'dentaku/token'

describe Dentaku::AST::And do
  let(:t) { Dentaku::AST::Logical.new Dentaku::Token.new(:logical, true)  }
  let(:f) { Dentaku::AST::Logical.new Dentaku::Token.new(:logical, false) }

  let(:five) { Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, 5) }

  let(:calculator) { Dentaku::Calculator.new }

  it 'performs logical AND' do
    node = described_class.new(t, f)
    expect(calculator.evaluate!(node)).to eq false
  end

  # it 'requires logical operands' do
  #   expect {
  #     described_class.new(t, five)
  #   }.to raise_error(RuntimeError, /requires logical operands/)

  #   expression = Dentaku::AST::LessThanOrEqual.new(five, five)
  #   expect {
  #     described_class.new(t, expression)
  #   }.not_to raise_error

  #   expression = Dentaku::AST::Or.new(t, f)
  #   expect {
  #     described_class.new(t, expression)
  #   }.not_to raise_error
  # end
end
