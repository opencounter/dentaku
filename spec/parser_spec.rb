require 'spec_helper'
require 'dentaku/token'
require 'dentaku/parser'

describe Dentaku::Parser do
  def self.should_not_parse(*expressions)
    describe "parse errors\n     " do
      expressions.each do |(expression, message)|
        it "#{expression}" do
          expect{ parse_expression(expression) }.to raise_error(Dentaku::ParseError, %r{#{ message }})
        end
      end
    end
  end

  def self.should_parse(*expressions)
    describe "parse success\n     " do
      expressions.each do |(expression, classType)|
        it "#{expression}" do
          ast = parse_expression(expression)
          expect(ast).to be_a(classType)
        end
      end
    end
  end

  def parse_expression(expression)
    Dentaku::Parser.new(Dentaku::Tokenizer.tokenize(expression)).parse
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
    expect(calculator.evaluate!(node, input(x: 3))).to eq 15
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

    expect(calculator.evaluate!(node, input(x: 3))).to eq(4)
  end

  should_parse(
    ["{ a: TRUE, b: false }", Dentaku::AST::Struct],
    ["[1, 2, 3]", Dentaku::AST::List],
    ["IF(1 = 2, { a: 1 }, { c: 3 })", Dentaku::AST::Function],
    ["IF(1 = 2, 'here', 'there')", Dentaku::AST::Function],
    ["{ a: { b: 2 } }", Dentaku::AST::Struct],
    ["if(2 = 1, (1%6), 7)", Dentaku::AST::Function],
    ["field:café", Dentaku::AST::Identifier],
    ["field:値", Dentaku::AST::Identifier],
    ["CASE
      WHEN baz THEN
        CASE
        WHEN 1 THEN 2
        END
      WHEN faz THEN 1
      END", Dentaku::AST::Case],
  )


  should_not_parse(
    ["foo bar", /unexpected output/i],
    [
      "IF(true, 3, 4)
       IF(true, 3, 4)", /unexpected output/i],

    ["(1 + 2 * 5", /'\(' missing closing '\)'/i],
    ["((1 + 2 * 5)", /'\(' missing closing '\)'/i],
    ["(1 + 2 * 5))", /extraneous closing '\)'/i],
    ["1 + 2 * 5))", /extraneous closing '\)'/i],
    ['"foo', /unbalanced quote/i],
    ['[1,2,[1]', /'\[' missing closing/i],
    ['[1,2', /missing closing/i],
    ['{a: 1, b: {a: 1}', /'\{' missing closing/i],
    ["CASE foo
      WHEN baz THEN 3
      WHEN faz THEN 1 ", /'CASE' missing closing 'END'/],
    ["CASE foo
      WHEN baz THEN 3
      WHEN faz
      END", /Expected case token, got/],
    ["CASE foo
      WHEN baz THEN 3
      WHEN faz 3
      END", /Expected case token, got/],
    ["CASE foo
      END", /`foo' is not a valid CASE condition/],
    ["CASE foo
      WHEN baz THEN 3
      IF(true, 1, 2)
      WHEN baz THEN 3
      END", /Expected first argument to be a CaseWhen, was \(3\)/],
    ["([)]", /Unexpected token in parenthesis/],
    ["field:$money", /Unknown token starting with "[$]mo"/]
  )
end
