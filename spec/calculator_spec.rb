require 'spec_helper'
require 'dentaku/calculator'

DENTAKU_TYPE_DEBUG = ENV['DENTAKU_TYPE_DEBUG'].to_i > 0

describe Dentaku::Calculator do
  let(:calculator)  { described_class.new.tap { |c| c.cache = {} } }

  def typecheck!(ast, vars)
    types = vars.transform_values do |val|
      case val
      when Numeric     then ':numeric'
      when true, false then ':bool'
      when Range       then ':range'
      when String      then ':string'
      when Missing     then val.type
      else raise "unknown value type: #{val.class}"
      end
    end

    checker = Dentaku::Type::StaticChecker.new(types)
    checker.check!(ast, debug: DENTAKU_TYPE_DEBUG)
  end

  def e(expr, vars={}, &b)
    calculator.evaluate(expr, input(vars), &b)
  end

  def e!(expr, vars={})
    @ast = calculator.ast(expr)
    typecheck!(@ast, vars)
    calculator.evaluate!(@ast, input(vars))
  end

  it 'evaluates an expression' do
    expect(e!('7+3')).to eq(10)
    expect(e!('2 -1')).to eq(1)
    expect(e!('-1 + 2')).to eq(1)
    expect(e!('1 - 2')).to eq(-1)
    expect(e!('1 - - 2')).to eq(3)
    expect(e!('-1 - - 2')).to eq(1)
    expect(e!('1 - - - 2')).to eq(-1)
    expect(e!('(-1 + 2)')).to eq(1)
    expect(e!('-(1 + 2)')).to eq(-3)
    expect(e!('2 ^ - 1')).to eq(0.5)
    expect(e!('2 ^ -(3 - 2)')).to eq(0.5)
    expect(e!('(2 + 3) - 1')).to eq(4)
    expect(e!('(-2 + 3) - 1')).to eq(0)
    expect(e!('(-2 - 3) - 1')).to eq(-6)
    expect(e!('1 + -(2 ^ 2)')).to eq(-3)
    expect(e!('3 + -num', num: 2)).to eq(1)
    expect(e!('-num + 3', num: 2)).to eq(1)
    expect(e!('10 ^ 2')).to eq(100)
    expect(e!('0 * 10 ^ -5')).to eq(0)
    expect(e!('3 + 0 * -3')).to eq(3)
    expect(e!('3 + 0 / -3')).to eq(3)
    expect(e!('15 % 8')).to eq(7)
    expect(e!('(((695759/735000)^(1/(1981-1991)))-1)*1000').round(4)).to eq(5.5018)
    expect(e!('0.253/0.253')).to eq(1)
    expect(e!('0.253/d', d: 0.253)).to eq(1)
    expect(e!("// this is a comment\n35")).to eq(35)
    expect(e!("36\n// this is a comment")).to eq(36)
    expect(e!("false and false or true")).to eq(true)
  end

  describe 'dependencies' do
    it "finds dependencies in a generic statement" do
      expect(calculator.dependencies("bob + dole / 3")).to eq(['bob', 'dole'])
    end
  end

  it 'evaluates a statement with no variables' do
    expect(e!('5+3')).to eq(8)
    expect(e!('(1+1+1)/3*100')).to eq(100)
  end

  it 'gives reasonable type errors' do
    expect { e!('if(foo = 10, foo + 1 + true + bar, { x: 1 })', foo: 'hello') }
      .to raise_error do |e|
      expect(e).to be_a Dentaku::Type::ErrorSet
      expect(e.message).to match /TypeMismatch/
      expect(e.message).to match /UnboundIdentifier `bar' of type :numeric/
    end
  end

  it 'allows trailing commas' do
    expect(e!('[1,2,3,]')).to eq([1,2,3])
  end

  it 'gives type errors for combinators' do
    expect { e!('12 OR 23') }.to raise_error do |e|
      expect(e).to be_a Dentaku::Type::ErrorSet
      expect(e.message).to match /TypeMismatch/
    end
  end

  it 'fails to evaluate unbound statements' do
    unbound = 'if(foo, concat([bar * 1.5], baz), zot)'

    expect { e!(unbound) }.to raise_error do |error|
      expect(error).to be_a Dentaku::Type::ErrorSet
      expect(error.message).to match %r(`foo' of type :bool)
      expect(error.message).to match %r(`bar' of type :numeric)
      expect(error.message).to match %r(`baz' of type \[:numeric\])
      expect(error.message).to match %r(`zot' of type \[:numeric\])
    end

    expect(e(unbound)).to be_nil
    expect(e(unbound) { :bar }).to eq :bar
    expect(e(unbound) { |e| e }).to eq unbound
  end

  it 'gives a good error message for an unknown typed missing variable' do
    expect { e!('foo') }.to raise_error { |e| expect(e.message).to match /`foo' of type %unknown-type/ }
    expect { e!('concat([], foo)') }.to raise_error { |e| expect(e.message).to match /`foo' of type \[%unknown-type\]/ }
    expect { e!('[foo]') }.to raise_error { |e| expect(e.message).to match /`foo' of type %unknown-type/ }
  end

  it 'rebinds for each evaluation' do
    expect(e!('foo * 2', foo: 2)).to eq(4)
    expect(e!('foo * 2', foo: 4)).to eq(8)
  end

  it 'accepts strings or symbols for binding keys' do
    expect(e!('foo * 2', foo: 2)).to eq(4)
    expect(e!('foo * 2', 'foo' => 4)).to eq(8)
  end

  it 'accepts digits in identifiers' do
    expect(e!('foo1 * 2', foo1: 2)).to eq(4)
    expect(e!('foo1 * 2', 'foo1' => 4)).to eq(8)
    expect(e!('1foo * 2', '1foo' => 2)).to eq(4)
    expect(e!('fo1o * 2', fo1o: 4)).to eq(8)
  end

  it 'compares string literals with string variables' do
    expect(e!('fruit = "apple"', fruit: 'apple')).to be_truthy
    expect(e!('fruit = "apple"', fruit: 'pear')).to be_falsey
  end

  it 'performs case-sensitive comparison' do
    expect(e!('fruit = "Apple"', fruit: 'apple')).to be_falsey
    expect(e!('fruit = "Apple"', fruit: 'Apple')).to be_truthy
  end

  it 'allows binding logical values' do
    expect(e!('some_boolean AND 7 > 5', some_boolean: true)).to be_truthy
    expect(e!('some_boolean AND 7 < 5', some_boolean: true)).to be_falsey
    expect(e!('some_boolean AND 7 > 5', some_boolean: false)).to be_falsey

    expect(e!('some_boolean OR 7 > 5', some_boolean: true)).to be_truthy
    expect(e!('some_boolean OR 7 < 5', some_boolean: true)).to be_truthy
    expect(e!('some_boolean OR 7 < 5', some_boolean: false)).to be_falsey
  end

  describe 'functions' do
    it 'include IF' do
      expect(e!('if(foo < 8, 10, 20)', foo: 2)).to eq(10)
      expect(e!('if(foo < 8, 10, 20)', foo: 9)).to eq(20)
      expect(e!('if (foo < 8, 10, 20)', foo: 2)).to eq(10)
      expect(e!('if (foo < 8, 10, 20)', foo: 9)).to eq(20)
    end
  end

  it 'include ROUND' do
    expect(e!('round(8.75)')).to eq(BigDecimal('9'))
    expect(e!('ROUND(apples * 0.93)', { apples: 10 })).to eq(9)
  end

  it 'include NOT' do
    expect(e!('NOT(some_boolean)', some_boolean: true)).to be_falsey
    expect(e!('NOT(some_boolean)', some_boolean: false)).to be_truthy

    expect(e!('NOT(some_boolean) AND 7 > 5', some_boolean: true)).to be_falsey
    expect(e!('NOT(some_boolean) OR 7 < 5', some_boolean: false)).to be_truthy
  end

  it 'evaluates functions with negative numbers' do
    expect(e!('if (-1 < 5, -1, 5)')).to eq(-1)
    expect(e!('if (-1 = -1, -1, 5)')).to eq(-1)
    expect(e!('round(-1.23)')).to eq(BigDecimal('-1'))
    expect(e!('NOT(some_boolean) AND -1 > 3', some_boolean: true)).to be_falsey
  end

  describe 'roundup' do
    it 'should accept second precision argument like in Office formula' do
      expect(e!('roundup(1.234, 2)')).to eq(1.24)
    end
  end

  describe 'rounddown' do
    it 'should accept second precision argument like in Office formula' do
      expect(e!('rounddown(1.234, 2)')).to eq(1.23)
    end
  end

  describe 'within' do
    it 'should check that a number is within a range' do
      expect(e!('within(1..3, 2)')).to be true
      expect(e!('within(1..2, 3)')).to be false
      expect(e!('within(1..3+4, 6)')).to be true
      expect(e!('within(1..3+4, 7)')).to be true
      expect(e!('within(1..3+4, 8)')).to be false
      expect(e!('within(1..foo, 6)', input(foo: 10))).to be true
    end
  end

  describe 'struct' do
    it 'handles struct' do
      result = e!('{code: field:code, value: val*10}', 'field:code': '23', val: 10)
      expect(result[:code]).to eq('23')
      expect(result[:value]).to eq(100)
    end

    it 'handles empty struct' do
      result = e!('{}')
      expect(result).to eq({})
    end

    it "gracefully fails when keys aren't present" do
      expect { e!('{a:1,b:2}') }.to raise_error(/Values without keys/)
    end

    it 'allows trailing commas',:jneen do
      result = e!("{a: 1, b: 2,}")
      expect(result[:a]).to eq(1)
      expect(result[:b]).to eq(2)

      result = e!("{a: 1, b: 2,//comment\n}")
      expect(result[:a]).to eq(1)
      expect(result[:b]).to eq(2)
    end
  end

  describe 'list' do
    it 'handles list' do
      result = e!('[field:code]', 'field:code': 23)
      expect(result).to eq([23])
    end

    it 'concats lists' do
      expect(e!('concat([2, 3 + 2, 4 - 1], [1, 7 * 2 + 3, 4])'))
        .to eq([2, 5, 3, 1, 17, 4])
    end
  end

  it 'handles multiline if statements' do
    formula = <<-FORMULA
      if
        (fruit='apple',
        (1 * quantity),
        (2 * quantity))
    FORMULA
    expect(e!(formula, quantity: 3, fruit: 'apple')).to eq(3)
    expect(e!(formula, quantity: 3, fruit: 'banana')).to eq(6)
  end

  describe 'case statements' do
    it 'handles complex then statements' do
      formula = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN (1 * quantity)
      WHEN 'banana'
        THEN 2 * quantity
      END
      FORMULA
      expect(e!(formula, quantity: 3, fruit: 'apple')).to eq(3)
      expect(e!(formula, quantity: 3, fruit: 'banana')).to eq(6)
    end

    it 'handles complex when statements' do
      formula = <<-FORMULA
      CASE number
      WHEN 2 * 2
        THEN 1
      WHEN 5..6
        THEN 2
      END
      FORMULA
      expect(e!(formula, number: 4)).to eq(1)
      expect(e!(formula, number: 6)).to eq(2)
    end

    it 'throws an exception when no match and there is no default value' do
      formula = <<-FORMULA
      CASE number
      WHEN 42
        THEN 1
      END
      FORMULA
      expect { e!(formula, number: 2) }
        .to raise_error("No block matched the switch value '2'")
    end

    it 'handles a default else statement' do
      formula = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN 1 * quantity
      WHEN 'banana'
        THEN 2 * quantity
      ELSE
        3 * quantity
      END
      FORMULA
      expect(e!(formula, quantity: 1, fruit: 'banana')).to eq(2)
      expect(e!(formula, quantity: 1, fruit: 'orange')).to eq(3)
    end

    it 'handles nested case statements' do
      formula = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN 1 * quantity
      WHEN 'banana'
        THEN
        CASE quantity
        WHEN 1 THEN 2
        WHEN 10 THEN
          CASE type
          WHEN 'organic' THEN 5
          ELSE 23
          END
        END
      END
      FORMULA
      value = e!(
        formula,
        type: 'organic', quantity: 10, fruit: 'banana'
      )
      expect(value).to eq(5)
    end

    it 'handles multiple nested case statements' do
      formula = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN
        CASE quantity
        WHEN 2 THEN 3
        END
      WHEN 'banana'
        THEN
        CASE quantity
        WHEN 1 THEN 2
        END
      END
      FORMULA
      value = e!(
        formula,
        quantity: 1, fruit: 'banana'
      )
      expect(value).to eq(2)

      value = e!(
        formula,
        quantity: 2, fruit: 'apple'
      )
      expect(value).to eq(3)
    end

    it 'handles empty case statements' do
      formula = <<-FORMULA
      CASE
      WHEN a = 1 THEN "a"
      WHEN b = 2 THEN "b"
      ELSE "c"
      END
      FORMULA

      expect(e!(formula, a: 1, b: missing(':numeric'))).to eq('a')
      expect(calculator.dependencies(@ast)).to eql ['a', 'b']

      expect(e!(formula, a: 0, b: 2)).to eq('b')
      expect(e!(formula, a: 0, b: 0)).to eq('c')
      expect { e!(formula, a: missing(':numeric'), b: missing(':numeric')) }
        .to raise_error(Dentaku::UnboundVariableError)
      expect { e!(formula, a: missing(':numeric'), b: 2) }
        .to raise_error(Dentaku::UnboundVariableError)
    end
  end


  it 'handles logic in case statements' do
    formula = <<-FORMULA
    CASE
    WHEN a AND b THEN 1
    WHEN a OR b THEN 2
    END
    FORMULA

    expect(e!(formula, a: true, b: false)).to eq(2)
  end

  describe 'math functions' do
    Math.methods(false).each do |method|
      it method do
        if [-1, 2].include?(Math.method(method).arity)
          expect(e!("#{method}(1,2)")).to eq Math.send(method, 1, 2)
        else
          expect(e!("#{method}(1)")).to eq Math.send(method, 1)
        end
      end
    end
  end
end
