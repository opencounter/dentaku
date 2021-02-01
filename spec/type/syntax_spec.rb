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

  it 'parses function with complex return type' do
    expr = Dentaku::Type::Syntax.parse_spec('foo({ id: :string, code: :string }) = { zones: [{ id: :string, code: :string, rule: { id: :numeric, name: :string, slug: :string, rule_type: :string, description: :string }, slug: :string, admin_name: :string, is_overlay: :bool, permission: { id: :numeric, code: :string, name: :string, slug: :string, category: :string, priority: :numeric, description: :string, display_name: :string, display_verb: :string, municipal_code_url: :string }, description: :string, display_name: :string, municipal_code_url: :string, development_standards_url: :string }], parcels: [{ key: :string, value: :string }] }')
    expect(expr.name).to eql('foo')
    expect(expr.arg_types.size).to be 1
    expect(expr.arg_types[0].repr).to eql("{id: :string, code: :string}")
    expect(expr.return_type.repr).to eql("{zones: :list({id: :string, code: :string, rule: {id: :numeric, name: :string, slug: :string, rule_type: :string, description: :string}, slug: :string, admin_name: :string, is_overlay: :bool, permission: {id: :numeric, code: :string, name: :string, slug: :string, category: :string, priority: :numeric, description: :string, display_name: :string, display_verb: :string, municipal_code_url: :string}, description: :string, display_name: :string, municipal_code_url: :string, development_standards_url: :string}), parcels: :list({key: :string, value: :string})}")
  end

  it 'parses type' do
    expr = Dentaku::Type::Syntax.parse_type(':numeric')
    expect(expr.name).to eql(:numeric)
  end

  it 'parses type as sym' do
    expr = Dentaku::Type::Syntax.parse_type(:numeric)
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

  it 'parses struct type' do
    type_syntax = '{ foo: :string, bar: { one: :string, two: :bool }, baz: [:numeric] }'
    expr = Dentaku::Type::Syntax.parse_type(type_syntax)
    expect(expr).to be_struct
    expect(expr.keys).to eql(["foo", "bar", "baz"])
    expect(expr.types[0].name).to eql(:string)

    expect(expr.types[1]).to be_struct
    expect(expr.types[1].keys).to eql(["one", "two"])
    expect(expr.types[1].types[0].name).to eql(:string)

    expect(expr.types[2].name).to eql(:list)
    expect(expr.types[2].arguments[0].name).to eql(:numeric)
  end

  it 'raises an error un undeclared types' do
    type_syntax = ':foo(%a)'
    expect { Dentaku::Type::Syntax.parse_type(type_syntax) }
      .to raise_error %r(undeclared param type :foo/1)
  end
end
