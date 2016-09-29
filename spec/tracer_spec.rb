require 'spec_helper'

describe Dentaku::Tracer do
  it 'traces stuff', focus: true do
    expr = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN (1 * quantity)
      WHEN 'banana'
        THEN (2 * foo)
      END
    FORMULA
      # expect(calculator.evaluate(formula, quantity: 3, fruit: 'apple')).to eq(3)
    result, trace = Dentaku::Calculator.new.evaluate_with_trace(expr, quantity: 3, fruit: 'apple')
    # binding.pry
    # 1

  end
end
