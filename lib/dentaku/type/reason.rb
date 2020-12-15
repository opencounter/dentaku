module Dentaku
  module Type
    class Reason < Variant
      variants(
        # known type of a literal
        literal: [:ast],

        # return value from a spec'd function
        retval: [:ast],

        # argument spec of a function
        arg: [:ast, :index],

        # known type of an operator
        operator: [:ast, :side],

        # received type of an identifier
        identifier: [:ast],

        # lists must all be the same type
        list_member: [:ast, :index],

        # more than one constraint together
        conjunction: [:left, :right],

        # if, for example :list(%a) = :list(%b) then %a = %b
        destructure: [:constraint, :index],


        # value in a dictionary 
        dictionary_key: [:ast, :key],

        # unused (?)
        # definition_arg: [:type_spec, :scope, :index],

        # used when typechecking a function definition
        # definition_retval: [:type_spec, :scope],


        # WHEN clauses must all be the same type as the inspected val
        case_when: [:ast, :index],

        # THEN clauses must be the same type as the return val
        case_then: [:ast, :index],

        # WHEN clauses when there is a range involved must inspect a
        # numeric value
        case_when_range: [:ast, :index],

        # ELSE clauses must be the same type as the return val
        case_else: [:ast],

        # marks the entire type of the CASE statement
        case_return: [:ast],

        # ranges must be composed of :numeric values
        range_element: [:ast, :side],

        # an external constraint that specifies the expected type
        # of the whole expression
        root: [],
      )

      def repr(depth=0)
        cases(
          conjunction: ->(left, right) { "#{left.repr_with_reason(depth+1)}, and #{right.repr_with_reason(depth+1)}" },
          literal: ->(ast) { "#{ast.repr} is a literal" },
          retval: ->(ast) { "return value of #{ast.function_name}" },
          arg: ->(ast, index) { "argument ##{index} of #{ast.function_name}" },
          operator: ->(ast, side) { "#{side_name(side)} of #{ast.operator}" },
          identifier: ->(ast) { "the type of `#{ast.repr}'" },
          list_member: ->(ast) { "elements of #{ast.repr} must all be the same type" },
          destructure: ->(constraint, index) { "inferred from #{constraint.repr}" },
          dictionary_key: ->(ast, key) { "known type at #{key} in a dictionary" },
          case_when: ->(ast, index) { "WHEN branch ##{index} of a CASE statement" },
          case_then: ->(ast, index) { "THEN branch ##{index} of a CASE statement" },
          case_when_range: ->(ast, index) { "numeric CASE statement using ranges" },
          case_else: ->(ast) { "ELSE branch of a CASE statement" },
          case_return: ->(ast) { "the return type of a CASE statement" },
          other: ->(*) { "#{_name}:#{@_values.inspect}" },
          range_element: ->(ast, side) { "#{side_name(side)} of a range" },
          root: -> { "expected type of the whole expression" },
        )
      end

      def side_name(side)
        return "value" if side == :return
        "#{side} side"
      end

      def ast_nodes
        cases(
          literal: ->(ast) { [ast] },
          retval: ->(ast) { [ast] },
          operator: ->(ast, *) { [ast] },
          identifier: ->(ast) { [ast] },
          destructure: ->(constraint, *) { constraint.ast_nodes },
          dictionary_key: ->(ast, *) { [ast] },
          list_member: ->(ast, *) { [ast] },
          case_when: ->(ast, *) { [ast] },
          case_then: ->(ast, *) { [ast] },
          case_when_range: ->(ast, *) { [ast] },
          case_else: ->(ast) { [ast] },
          case_return: ->(ast) { [ast] },
          conjunction: ->(left, right) { right.ast_nodes },
          other: []
        )
      end
    end
  end
end
