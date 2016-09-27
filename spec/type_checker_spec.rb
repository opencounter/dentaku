require 'dentaku/calculator'
require 'dentaku/constraint_context'
require 'dentaku/constraint'
require 'dentaku/reason'

describe 'Type Checker' do
  it 'works' do
    context = Dentaku::StaticConstraintContext.new(
      foo: [:concrete, :string],
      bar: [:concrete, :numeric],
    )

    expression = "if(foo, bar, 3)"
    ast = Dentaku::Calculator.new.ast(expression)
    # binding.pry
    # pp ast.constraints(context)
  end
end
