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

    # this is not a parse error, it's a type error
    valid("IF(true, 3)", Dentaku::AST::Function)

    valid("[a,b,]", Dentaku::AST::List)
    valid("f(a,b,)", Dentaku::AST::Function)
  end


  describe 'invalid expressions' do
    invalid("foo bar", /too many expressions/i)
    invalid("IF(true, 3, 4) IF(true, 3, 4)", /too many expressions/i)

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
    invalid("CASE foo WHEN baz THEN 3 IF(true, 1, 2) WHEN baz THEN 3 END", /too many expressions/)
    invalid("([)]", /expected square bracket, got parenthesis/)
    invalid("field:$money", /Unknown token starting with `[$]mo'/)
    invalid("case 1 when 2 then 3 else end", /empty ELSE clause/)
    invalid("a * b(c, d), (e)", /stray comma/)

    # this one catches *both* errors
    invalid("a * b(c, d), ()", /stray comma/)
    invalid("a * b(c, d), ()", /empty expression/)

    invalid("f(a,,b)", /stray comma/)
    invalid("f(,a,b)", /stray comma/)
    invalid("f(a,,)", /stray comma/)
    invalid("[a,,b]", /stray comma/)
    invalid("[,a,b]", /stray comma/)
    invalid("[a,,]", /stray comma/)
    invalid("OR 1", /empty expression/)
    invalid("1 OR", /empty expression/)
    invalid("= 2", /empty expression/)
    invalid("2 = ", /empty expression/)
    invalid("3+", /empty expression/)
    invalid("4..", /empty expression/)
    invalid("3+2/", /empty expression/)
    invalid("{a:}", /empty expression/)
    invalid("{a:,,b: c}", /stray comma/)
  end
end
