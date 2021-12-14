require 'spec_helper'

describe Dentaku::AST::Addition do
  let(:node) { Dentaku::Syntax.parse('5 + 6') }
  let(:calculator) { Dentaku::Calculator.new }

  it 'performs addition' do
    expect(calculator.evaluate!(node)).to eq 11
  end
end
