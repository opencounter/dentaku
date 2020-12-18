require 'spec_helper'

describe Dentaku::Tracer do
  it 'traces stuff' do
    expr = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN (1 * quantity)
      WHEN 'banana'
        THEN (2 * foo)
      END
    FORMULA
      # expect(calculator.evaluate(formula, quantity: 3, fruit: 'apple')).to eq(3)
    result, trace = Dentaku::Calculator.new.evaluate_with_trace(expr, input(quantity: 3, fruit: 'apple'))

  end
end
