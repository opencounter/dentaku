require 'spec_helper'

describe 'Type Checker' do
  def self.process_expression(expression)
    if expression.is_a?(Array)
      expression, types = *expression
    else
      types = {}
    end

    checker = Dentaku::Type::StaticChecker.new(types)
    ast = Dentaku::Calculator.new.ast(expression)
    return [ast, checker]
  end

  def self.should_type_check(*expressions)
    describe "checking" do
      expressions.each do |expression|
        ast, checker = process_expression(expression)

        describe "expression(#{expression})" do
          it "checks" do
            checker.check!(ast)
          end
        end
      end
    end
  end

  def self.should_not_type_check(*expressions)
    describe "checking" do
      expressions.each do |expression|
        error_match = expression.is_a?(Array) ? expression[2..] : []

        ast, checker = process_expression(expression)

        describe "expression(#{expression})" do
          it "fails check" do
            expect {
              checker.check!(ast)
            }.to raise_error(Dentaku::Type::ErrorSet, *error_match)
          end
        end
      end
    end
  end

  should_type_check(
    "1 + 5 + 10",
    "[1,2,3]",
    "'foo' = 'fooz'",
    "'foo' != 'fooz'",
    ["foo + bar - 10", { foo: ":numeric", bar: ":numeric" }],
    ["if(foo, 1, bar)", { foo: ":bool", bar: ":numeric" }],
    ['concat(concat(foo, ["baz"]), ["bar"])', { foo: "[:string]" }],
    [
      'CASE foo
         WHEN 1..5 THEN 2
         WHEN 6 THEN 23
         ELSE 3
       END', { foo: ":numeric" }
    ],
    [ 'CASE
       WHEN foo THEN 1
       WHEN false THEN 3
       ELSE 4
       END', { foo: ':bool' }
    ],
  )

  context 'expected return type' do
    ast, checker = process_expression('if(true, 1, 2)')

    it 'validates a correct return type' do
      checker.check!(ast, expected_type: Dentaku::Type.build(&:numeric))
    end

    it 'invalidates an incorrect return type' do
      expect {
        checker.check!(ast, expected_type: Dentaku::Type.build(&:bool))
      }.to raise_error(Dentaku::Type::ErrorSet,
                       /:numeric = :bool|:bool = :numeric/)
    end
  end

  should_not_type_check(
    "1 + 'foo'",
    "[1,2,'3']",
    "'foo' = 5",
    "'foo' != 5",
    "5 = [5]",
    ["1 + foo", { foo: ":string" }],
    ["1 + (5*foo)", { foo: ":bool" }],
    ['if(foo, 1, "bar")', { foo: ":bool" }],
    ['if(foo, 1, 2)', { foo: ":string" }],
    ['concat(foo, [3])', { foo: "[:string]" }],
    ['concat(concat(foo, [3]), ["3"])', { foo: "[:string]" }],
    [
      'CASE foo
         WHEN 5 THEN 2
         ELSE "3"
       END', { foo: ":numeric" }
    ],
    [
      'CASE foo
         WHEN 5 THEN 2
         ELSE 3
       END', { foo: ":string" }
    ],
    ['CASE
     WHEN 1 THEN 2
     WHEN 3 THEN 4
     END', {}, /(:numeric = :bool|:bool = :numeric).*[(]WHEN branch/]
  )

  pending 'checks functions' do
    fail
    func_type = 'c([%a], [%a]) = [%a]'
    func_impl = 'concat(arg:1, arg:2)'

    ast = Dentaku::Calculator.new.ast(func_impl)

    context = Dentaku::Type::FunctionChecker.new(func_type)

    expect{context.check!(ast)}.not_to raise_error
  end
end
