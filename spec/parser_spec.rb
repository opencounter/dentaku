require 'spec_helper'
require 'dentaku'

describe Dentaku::Syntax::Parser do
  def self.invalid(expression, message, *a)
    it "is invalid: <#{expression}> - #{message}", *a do
      ast = parse_expression(expression)
      expect(ast).not_to be_valid
      expect(ast.repr).to match(message)
    end
  end

  def self.valid(expression, class_, *a)
    it "is valid: (#{expression})", *a do
      ast = parse_expression(expression)
      expect(ast).to be_valid
      expect(ast).to be_a(class_)
    end
  end

  def parse_expression(expression)
    Dentaku::Syntax.parse(expression)
  end

  let(:calculator) { Dentaku::Calculator.new }

  describe 'valid expressions' do
    valid("{ a: TRUE, b: false }", Dentaku::AST::Struct)
    valid("[1, 2, 3]", Dentaku::AST::List)
    valid("IF(1 = 2, { a: 1 }, { c: 3 })", Dentaku::AST::Function)
    valid("IF(1 = 2, 'here', 'there')", Dentaku::AST::Function)
    valid("{ a: { b: 2 } }", Dentaku::AST::Struct)
    valid("if(2 = 1, (1%6), 7)", Dentaku::AST::Function)
    valid("field:café", Dentaku::AST::Identifier)
    valid("field:値", Dentaku::AST::Identifier)
    valid("CASE
        WHEN baz THEN
          CASE
          WHEN 1 THEN 2
          END
        WHEN faz THEN 1
        END", Dentaku::AST::Case)
  end


  describe 'invalid expressions' do
    invalid("foo bar", /unrecognized syntax/i)
    invalid("IF(true, 3, 4) IF(true, 3, 4)", /unrecognized syntax/i)

    invalid("(1 + 2 * 5", /unclosed parenthesis/i)
    invalid("((1 + 2 * 5)", /unclosed parenthesis/i)
    invalid("(1 + 2 * 5))", /extraneous closing parenthesis/i)
    invalid("1 + 2 * 5))", /extraneous closing parenthesis/i)
    invalid('"foo', /unbalanced quote/i)
    invalid('(1,2,[1]', /unclosed parenthesis/i)
    invalid('[1,2', /unclosed square bracket/i)
    invalid('{a: 1, b: {a: 1}', /unclosed curly brace/i)
    invalid("CASE foo WHEN baz THEN 3 WHEN faz THEN 1 ", /unclosed CASE keyword/)
    invalid("CASE foo WHEN baz THEN 3 WHEN faz END", /hanging WHEN clause/)
    invalid("CASE foo WHEN baz THEN 3 WHEN faz 3 END", /hanging WHEN clause/)
    invalid("CASE foo END", /a CASE statement must have at least one clause/)
    invalid("CASE foo WHEN baz THEN 3 IF(true, 1, 2) WHEN baz THEN 3 END", /unrecognized syntax/)
    invalid("([)]", /expected square bracket, got parenthesis/)
    invalid("field:$money", /Unknown token starting with `[$]mo'/)
    invalid("case 1 when 2 then 3 else end", /unrecognized syntax/)
  end
end
