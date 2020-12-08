require 'spec_helper'
require 'dentaku/calculator'

describe Dentaku::Calculator do
  let(:calculator)  { described_class.new }

  it 'evaluates an expression' do
    expect(calculator.evaluate('7+3')).to eq(10)
    expect(calculator.evaluate('2 -1')).to eq(1)
    expect(calculator.evaluate('-1 + 2')).to eq(1)
    expect(calculator.evaluate('1 - 2')).to eq(-1)
    expect(calculator.evaluate('1 - - 2')).to eq(3)
    expect(calculator.evaluate('-1 - - 2')).to eq(1)
    expect(calculator.evaluate('1 - - - 2')).to eq(-1)
    expect(calculator.evaluate('(-1 + 2)')).to eq(1)
    expect(calculator.evaluate('-(1 + 2)')).to eq(-3)
    expect(calculator.evaluate('2 ^ - 1')).to eq(0.5)
    expect(calculator.evaluate('2 ^ -(3 - 2)')).to eq(0.5)
    expect(calculator.evaluate('(2 + 3) - 1')).to eq(4)
    expect(calculator.evaluate('(-2 + 3) - 1')).to eq(0)
    expect(calculator.evaluate('(-2 - 3) - 1')).to eq(-6)
    expect(calculator.evaluate('1 + -(2 ^ 2)')).to eq(-3)
    expect(calculator.evaluate('3 + -num', input(num: 2))).to eq(1)
    expect(calculator.evaluate('-num + 3', input(num: 2))).to eq(1)
    expect(calculator.evaluate('10 ^ 2')).to eq(100)
    expect(calculator.evaluate('0 * 10 ^ -5')).to eq(0)
    expect(calculator.evaluate('3 + 0 * -3')).to eq(3)
    expect(calculator.evaluate('3 + 0 / -3')).to eq(3)
    expect(calculator.evaluate('15 % 8')).to eq(7)
    expect(calculator.evaluate('(((695759/735000)^(1/(1981-1991)))-1)*1000').round(4)).to eq(5.5018)
    expect(calculator.evaluate('0.253/0.253')).to eq(1)
    expect(calculator.evaluate('0.253/d', input(d: 0.253))).to eq(1)
    expect(calculator.evaluate('1..3 = 2')).to eq(true)
  end

  describe 'dependencies' do
    it "finds dependencies in a generic statement" do
      expect(calculator.dependencies("bob + dole / 3")).to eq(['bob', 'dole'])
    end
  end

  it 'evaluates a statement with no variables' do
    expect(calculator.evaluate('5+3')).to eq(8)
    expect(calculator.evaluate('(1+1+1)/3*100')).to eq(100)
  end

  it 'fails to evaluate unbound statements' do
    unbound = 'foo * 1.5'
    expect { calculator.evaluate!(unbound) }.to raise_error(Dentaku::UnboundVariableError)
    expect { calculator.evaluate!(unbound) }.to raise_error do |error|
      expect(error.unbound_variables).to eq ['foo']
    end
    expect(calculator.evaluate(unbound)).to be_nil
    expect(calculator.evaluate(unbound) { :bar }).to eq :bar
    expect(calculator.evaluate(unbound) { |e| e }).to eq unbound
  end

  it 'rebinds for each evaluation' do
    expect(calculator.evaluate('foo * 2', input(foo: 2))).to eq(4)
    expect(calculator.evaluate('foo * 2', input(foo: 4))).to eq(8)
  end

  it 'accepts strings or symbols for binding keys' do
    expect(calculator.evaluate('foo * 2', input(foo: 2))).to eq(4)
    expect(calculator.evaluate('foo * 2', 'foo' => 4)).to eq(8)
  end

  it 'accepts digits in identifiers' do
    expect(calculator.evaluate('foo1 * 2', input(foo1: 2))).to eq(4)
    expect(calculator.evaluate('foo1 * 2', input('foo1' => 4))).to eq(8)
    expect(calculator.evaluate('1foo * 2', input('1foo' => 2))).to eq(4)
    expect(calculator.evaluate('fo1o * 2', input(fo1o: 4))).to eq(8)
  end

  it 'compares string literals with string variables' do
    expect(calculator.evaluate('fruit = "apple"', input(fruit: 'apple'))).to be_truthy
    expect(calculator.evaluate('fruit = "apple"', input(fruit: 'pear'))).to be_falsey
  end

  it 'performs case-sensitive comparison' do
    expect(calculator.evaluate('fruit = "Apple"', input(fruit: 'apple'))).to be_falsey
    expect(calculator.evaluate('fruit = "Apple"', input(fruit: 'Apple'))).to be_truthy
  end

  it 'allows binding logical values' do
    expect(calculator.evaluate('some_boolean AND 7 > 5', input(some_boolean: true))).to be_truthy
    expect(calculator.evaluate('some_boolean AND 7 < 5', input(some_boolean: true))).to be_falsey
    expect(calculator.evaluate('some_boolean AND 7 > 5', input(some_boolean: false))).to be_falsey

    expect(calculator.evaluate('some_boolean OR 7 > 5', input(some_boolean: true))).to be_truthy
    expect(calculator.evaluate('some_boolean OR 7 < 5', input(some_boolean: true))).to be_truthy
    expect(calculator.evaluate('some_boolean OR 7 < 5', input(some_boolean: false))).to be_falsey
  end

  describe 'functions' do
    it 'include IF' do
      expect(calculator.evaluate('if(foo < 8, 10, 20)', input(foo: 2))).to eq(10)
      expect(calculator.evaluate('if(foo < 8, 10, 20)', input(foo: 9))).to eq(20)
      expect(calculator.evaluate('if (foo < 8, 10, 20)', input(foo: 2))).to eq(10)
      expect(calculator.evaluate('if (foo < 8, 10, 20)', input(foo: 9))).to eq(20)
    end
  end

  it 'include ROUND' do
    expect(calculator.evaluate('round(8.75)')).to eq(BigDecimal('9'))
    expect(calculator.evaluate('ROUND(apples * 0.93)', input({ apples: 10 }))).to eq(9)
  end

  it 'include NOT' do
    expect(calculator.evaluate('NOT(some_boolean)', input(some_boolean: true))).to be_falsey
    expect(calculator.evaluate('NOT(some_boolean)', input(some_boolean: false))).to be_truthy

    expect(calculator.evaluate('NOT(some_boolean) AND 7 > 5', input(some_boolean: true))).to be_falsey
    expect(calculator.evaluate('NOT(some_boolean) OR 7 < 5', input(some_boolean: false))).to be_truthy
  end

  it 'evaluates functions with negative numbers' do
    expect(calculator.evaluate('if (-1 < 5, -1, 5)')).to eq(-1)
    expect(calculator.evaluate('if (-1 = -1, -1, 5)')).to eq(-1)
    expect(calculator.evaluate('round(-1.23)')).to eq(BigDecimal('-1'))
    expect(calculator.evaluate('NOT(some_boolean) AND -1 > 3', input(some_boolean: true))).to be_falsey
  end

  describe 'roundup' do
    it 'should accept second precision argument like in Office formula' do
      expect(calculator.evaluate('roundup(1.234, 2)')).to eq(1.24)
    end
  end

  describe 'rounddown' do
    it 'should accept second precision argument like in Office formula' do
      expect(calculator.evaluate('rounddown(1.234, 2)')).to eq(1.23)
    end
  end

  describe 'dictionary' do
    it 'handles dictionary' do
      result = calculator.evaluate('{code: field:code, value: val*10}', input('field:code': '23', val: 10))
      expect(result[:code]).to eq('23')
      expect(result[:value]).to eq(100)
    end
  end

  describe 'list' do
    it 'handles list' do
      result = calculator.evaluate('[field:code]', input('field:code': 23))
      expect(result).to eq([23])
    end

    it 'concats lists' do
      ast = calculator.ast('concat([2, 3 + 2, 4 - 1], [1, 7 * 2 + 3, 4])')
      type_checker = Dentaku::Type::StaticChecker.new({})
      type_checker.check!(ast)
      result = calculator.evaluate!(ast)
      expect(result).to eq([2, 5, 3, 1, 17, 4])
    end
  end

  it 'handles multiline if statements' do
    formula = <<-FORMULA
      if
        (fruit='apple',
        (1 * quantity),
        (2 * quantity))
    FORMULA
    expect(calculator.evaluate(formula, input(quantity: 3, fruit: 'apple'))).to eq(3)
    expect(calculator.evaluate(formula, input(quantity: 3, fruit: 'banana'))).to eq(6)
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
      expect(calculator.evaluate(formula, input(quantity: 3, fruit: 'apple'))).to eq(3)
      expect(calculator.evaluate(formula, input(quantity: 3, fruit: 'banana'))).to eq(6)
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
      expect(calculator.evaluate(formula, input(number: 4))).to eq(1)
      expect(calculator.evaluate(formula, input(number: 6))).to eq(2)
    end

    it 'throws an exception when no match and there is no default value' do
      formula = <<-FORMULA
      CASE number
      WHEN 42
        THEN 1
      END
      FORMULA
      expect { calculator.evaluate(formula, input(number: 2)) }
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
      expect(calculator.evaluate(formula, input(quantity: 1, fruit: 'banana'))).to eq(2)
      expect(calculator.evaluate(formula, input(quantity: 1, fruit: 'orange'))).to eq(3)
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
      value = calculator.evaluate(
        formula,
        input(type: 'organic', quantity: 10, fruit: 'banana')
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
      value = calculator.evaluate(
        formula,
        input(quantity: 1, fruit: 'banana')
      )
      expect(value).to eq(2)

      value = calculator.evaluate(
        formula,
        input(quantity: 2, fruit: 'apple')
      )
      expect(value).to eq(3)
    end

    it 'handles case statements in if' do
      formula = <<-FORMULA
      if(
        (fruit='apple'),
        CASE quantity
        WHEN 1 THEN 100
        WHEN 2 THEN 1000
        ELSE 10000
        END,
        5000)
      FORMULA
      value = calculator.evaluate(
        formula,
        input(quantity: 1, fruit: 'banana')
      )
      expect(value).to eq(5000)

      value = calculator.evaluate(
        formula,
        input(quantity: 2, fruit: 'apple')
      )
      expect(value).to eq(1000)
    end

    it 'handles case statements in if in case' do
      formula = <<-FORMULA
      CASE country
      WHEN 'japan'
      THEN if(
        (fruit='apple'),
        CASE quantity
        WHEN 1 THEN 100
        WHEN 2 THEN 1000
        ELSE 10000
        END,
        5000)
      ELSE 25
      END
      FORMULA
      value = calculator.evaluate(
        formula,
        input(country: 'japan', quantity: 1, fruit: 'banana')
      )
      expect(value).to eq(5000)

      value = calculator.evaluate(
        formula,
        input(country: 'china', quantity: 2, fruit: 'apple')
      )
      expect(value).to eq(25)
    end
  end

  describe 'math functions' do
    Math.methods(false).each do |method|
      it method do
        if [-1, 2].include?(Math.method(method).arity)
          expect(calculator.evaluate("#{method}(1,2)")).to eq Math.send(method, 1, 2)
        else
          expect(calculator.evaluate("#{method}(1)")).to eq Math.send(method, 1)
        end
      end
    end
  end
end
