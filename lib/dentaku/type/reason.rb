module Dentaku
  module Type
    class Reason < Variant
      variants(
        literal: [:ast],
        retval: [:ast],
        arg: [:ast, :index],
        operator: [:ast, :side],
        identifier: [:ast],
        dictionary_key: [:ast, :key],
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
      )
      def repr
        cases(
          conjunction: ->(left, right) { "#{left.repr} => #{right.repr}" },
          literal: ->(ast) { "LIT: #{ast.repr}" },
          other: ->(*) { "#{_name}:#{inspect}" }
        )
      end
    end
  end
end
