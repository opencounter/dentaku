module Dentaku
  module Type
    class Reason < Variant
      variants(
        literal: [:ast],
        retval: [:ast],
        arg: [:ast, :index],
        operator: [:ast, :side],
        identifier: [:ast],
        list_member: [:ast, :index],
        conjunction: [:left, :right],
        destructure: [:constraint, :index],
        dictionary_key: [:constraint, :key],
        definition_arg: [:type_spec, :scope, :index],
        definition_retval: [:type_spec, :scope],
        case_when: [:ast, :index],
        case_then: [:ast, :index],
        case_when_range: [:ast, :index],
        case_else: [:ast],
        case_return: [:ast],
        range_element: [:ast, :side],
      )

      def repr
        cases(
          conjunction: ->(left, right) { "TypeMismatch(#{left.repr},#{right.repr})" },
          literal: ->(ast) { "LIT: #{ast.repr}" },
          other: ->(*) { "#{_name}:#{@_values.inspect}" }
        )
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
