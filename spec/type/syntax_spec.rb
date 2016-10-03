require 'spec_helper'

describe Dentaku::Type::Syntax do
  it 'tokenizes' do
    tokens = Dentaku::Type::Syntax::Token.tokenize('foo bar :baz()').to_a

    expect(tokens[0].name).to eql(:NAME)
    expect(tokens[0].value).to eql('foo')

    expect(tokens[1].name).to eql(:NAME)
    expect(tokens[1].value).to eql('bar')

    expect(tokens[2].name).to eql(:PARAM)
    expect(tokens[2].value).to eql('baz')

    expect(tokens[3].name).to eql(:LPAREN)
    expect(tokens[4].name).to eql(:RPAREN)
  end

  it 'parses function' do
    expr = Dentaku::Type::Syntax.parse_spec('foo(:numeric) = :bool')
    expect(expr.name).to eql('foo')
    expect(expr.arg_types.size).to be 1
    expect(expr.arg_types[0].repr).to eql(':numeric')
    expect(expr.return_type.repr).to eql(':bool')
  end

  it 'parses type' do
    expr = Dentaku::Type::Syntax.parse_type(':numeric')
    expect(expr.name).to eql(:numeric)
  end

  it 'parses nested type' do
    expr = Dentaku::Type::Syntax.parse_type('[[:numeric]]')
    expect(expr.name).to eql(:list)
    expect(expr.arguments.length).to be 1
    expect(expr.arguments[0].name).to eql(:list)

    expect(expr.arguments[0].arguments.length).to be 1
    expect(expr.arguments[0].arguments[0].name).to eql(:numeric)
  end
end
