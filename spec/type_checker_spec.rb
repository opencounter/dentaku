require 'dentaku/calculator'
require 'dentaku/constraint_context'
require 'dentaku/constraint'
require 'dentaku/reason'

describe 'Type Checker' do
  it 'works' do
    context = Dentaku::StaticConstraintContext.new(
      foo: [:concrete, :string],
      bar: [:concrete, :numeric],
      baz: [:concrete, :numeric],
    )

    expression = "if(foo, bar, 3)"
    ast = Dentaku::Calculator.new.ast(expression)
    context.check!(ast)

    expression = "concat(foo, concat(bar, 3))"
    ast = Dentaku::Calculator.new.ast(expression)


    expression = "bar + baz"
    ast = Dentaku::Calculator.new.ast(expression)
    solutions = context.check!(ast)
    # binding.pry
    # puts
  end

  it 'checks lists' do
    context = Dentaku::StaticConstraintContext.new(
      foo: "[:numeric]",
      bar: "[:numeric]",
    )
    expression = "concat(foo, bar)"
    ast = Dentaku::Calculator.new.ast(expression)
    solved = context.check!(ast)
  end

  it 'checks functions' do
    func_type = 'c([%a], [%a]) = [%a]'
    func_impl = 'concat(arg:1, arg:2)'

    ast = Dentaku::Calculator.new.ast(func_impl)

    context = Dentaku::FunctionConstraintContext.new(func_type)

    scope, solutions = context.check!(ast, debug: 1)
  end

  it 'checks cases', focus: true do
    expr = "
      CASE 1
      WHEN 1..3 THEN '5'
      WHEN 4 THEN '6'
      ELSE '7'
      END
    "
    ast = Dentaku::Calculator.new.ast(expr)
    context = Dentaku::StaticConstraintContext.new
    context.check!(ast, debug: true)
  end
end
