require 'spec_helper'

describe Dentaku::AST::Division do
  let(:node) { Dentaku::Syntax.parse('5 / 6') }

  let(:calculator) { Dentaku::Calculator.new }

  it 'performs division' do
    expect(calculator.evaluate!(node).round(4)).to eq 0.8333
  end

  # TODO: spec for DivideByZero
end
