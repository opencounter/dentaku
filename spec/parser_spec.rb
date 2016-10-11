require 'spec_helper'
require 'dentaku/token'
require 'dentaku/parser'

describe Dentaku::Parser do
  def parse_expression(expression)
    Dentaku::Parser.new(Dentaku::Tokenizer.new.tokenize(expression)).parse
  rescue => e
    # binding.pry
    raise e
  end

  let(:calculator) { Dentaku::Calculator.new }

  it 'is constructed from a token' do
    token = Dentaku::Token.new(:numeric, 5)
    node  = described_class.new([token]).parse
    expect(calculator.evaluate!(node)).to eq 5
  end

  it 'performs simple addition' do
    five = Dentaku::Token.new(:numeric, 5)
    plus = Dentaku::Token.new(:operator, :add)
    four = Dentaku::Token.new(:numeric, 4)

    node  = described_class.new([five, plus, four]).parse
    expect(calculator.evaluate!(node)).to eq 9
  end

  it 'compares two numbers' do
    five = Dentaku::Token.new(:numeric, 5)
    lt   = Dentaku::Token.new(:comparator, :lt)
    four = Dentaku::Token.new(:numeric, 4)

    node  = described_class.new([five, lt, four]).parse
    expect(calculator.evaluate!(node)).to eq false
  end

  it 'performs multiple operations in one stream' do
    five  = Dentaku::Token.new(:numeric, 5)
    plus  = Dentaku::Token.new(:operator, :add)
    four  = Dentaku::Token.new(:numeric, 4)
    times = Dentaku::Token.new(:operator, :multiply)
    three = Dentaku::Token.new(:numeric, 3)

    node  = described_class.new([five, plus, four, times, three]).parse
    expect(calculator.evaluate!(node)).to eq 17
  end

  it 'respects order of operations' do
    five  = Dentaku::Token.new(:numeric, 5)
    times = Dentaku::Token.new(:operator, :multiply)
    four  = Dentaku::Token.new(:numeric, 4)
    plus  = Dentaku::Token.new(:operator, :add)
    three = Dentaku::Token.new(:numeric, 3)

    node  = described_class.new([five, times, four, plus, three]).parse
    expect(calculator.evaluate!(node)).to eq 23
  end

  it 'respects grouping by parenthesis' do
    lpar  = Dentaku::Token.new(:grouping, :open)
    five  = Dentaku::Token.new(:numeric, 5)
    plus  = Dentaku::Token.new(:operator, :add)
    four  = Dentaku::Token.new(:numeric, 4)
    rpar  = Dentaku::Token.new(:grouping, :close)
    times = Dentaku::Token.new(:operator, :multiply)
    three = Dentaku::Token.new(:numeric, 3)

    node  = described_class.new([lpar, five, plus, four, rpar, times, three]).parse
    expect(calculator.evaluate!(node)).to eq 27
  end

  it 'evaluates functions' do
    fn    = Dentaku::Token.new(:function, :if)
    fopen = Dentaku::Token.new(:grouping, :open)
    five  = Dentaku::Token.new(:numeric, 5)
    lt    = Dentaku::Token.new(:comparator, :lt)
    four  = Dentaku::Token.new(:numeric, 4)
    comma = Dentaku::Token.new(:grouping, :comma)
    three = Dentaku::Token.new(:numeric, 3)
    two   = Dentaku::Token.new(:numeric, 2)
    rpar  = Dentaku::Token.new(:grouping, :close)

    node  = described_class.new([fn, fopen, five, lt, four, comma, three, comma, two, rpar]).parse
    expect(calculator.evaluate!(node)).to eq 2
  end

  it 'represents formulas with variables' do
    five  = Dentaku::Token.new(:numeric, 5)
    times = Dentaku::Token.new(:operator, :multiply)
    x     = Dentaku::Token.new(:identifier, :x)

    node  = described_class.new([five, times, x]).parse
    expect { calculator.evaluate!(node) }.to raise_error(Dentaku::UnboundVariableError)
    expect(calculator.evaluate!(node, x: 3)).to eq 15
  end

  it 'evaluates boolean expressions' do
    d_true  = Dentaku::Token.new(:logical, true)
    d_and   = Dentaku::Token.new(:combinator, :and)
    d_false = Dentaku::Token.new(:logical, false)

    node  = described_class.new([d_true, d_and, d_false]).parse
    expect(calculator.evaluate!(node)).to eq false
  end

  it 'evaluates a case statement' do
    case_start  = Dentaku::Token.new(:case, :open)
    x     = Dentaku::Token.new(:identifier, :x)
    case_when1 = Dentaku::Token.new(:case, :when)
    one  = Dentaku::Token.new(:numeric, 1)
    case_then1 = Dentaku::Token.new(:case, :then)
    two  = Dentaku::Token.new(:numeric, 2)
    case_when2 = Dentaku::Token.new(:case, :when)
    three  = Dentaku::Token.new(:numeric, 3)
    case_then2 = Dentaku::Token.new(:case, :then)
    four  = Dentaku::Token.new(:numeric, 4)
    case_close  = Dentaku::Token.new(:case, :close)

    node  = described_class.new(
      [case_start,
       x,
       case_when1,
       one,
       case_then1,
       two,
       case_when2,
       three,
       case_then2,
       four,
       case_close]).parse

    expect(calculator.evaluate!(node, x: 3)).to eq(4)
  end

  describe "ParseError" do
    it 'checks case end' do
      expression = "
      CASE foo
      WHEN baz THEN 3
      WHEN faz THEN 1
      "
      expect {
        parse_expression(expression)
      }.to raise_error(Dentaku::ParseError)
    end

    it 'checks case switch' do
      expression = "
      CASE
      WHEN baz THEN
        CASE
        WHEN 1 THEN 2
        END
      WHEN faz THEN 1
      END
      "
      expect {
        parse_expression(expression)
      }.to raise_error(Dentaku::ParseError)
    end

    it 'checks case thens' do
      expression = "
      CASE foo
      WHEN baz THEN 3
      WHEN faz
      END
      "
      expect {
        parse_expression(expression)
      }.to raise_error(Dentaku::ParseError)
    end

    it 'checks function arity' do
      expression = "if(foo, 1)"
      expect {
        parse_expression(expression)
      }.to raise_error(Dentaku::ParseError)
    end

    it 'checks user function arity' do
      Dentaku::AST::Function.register("add3(:numeric, :numeric, :numeric) = :numeric", ->(n1,n2,n3) { n1 + n2 + n3 })
      expression = "add3(2, 1)"
      expect {
        parse_expression(expression)
      }.to raise_error(Dentaku::ParseError)

      expression = "add3(2, 1, 5, 6)"
      expect {
        parse_expression(expression)
      }.to raise_error(Dentaku::ParseError)
    end

    it "doesn't allow using function names as identifiers" do
      expression = "1 + if"
      expect {
        parse_expression(expression)
      }.to raise_error(Dentaku::ParseError)
    end

    it "doesn't allow unbalanced parens" do
      expression = "(1 + 2 * 5"
      expect {
        parse_expression(expression)
      }.to raise_error(Dentaku::ParseError)
    end

    it "doesn't allow unbalanced quotes" do
      expression = '"foo'
      expect {
        parse_expression(expression)
      }.to raise_error(Dentaku::ParseError)
    end
  end
end
