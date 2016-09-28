require_relative './operation'

module Dentaku
  module AST
    class Combinator < Operation
      def types
        [:bool, :bool, :bool]
      end
    end

    class And < Combinator
      def value(context={})
        left.value(context) && right.value(context)
      end

      def repr
        "(#{left.repr} AND #{right.repr})"
      end
    end

    class Or < Combinator
      def value(context={})
        left.value(context) || right.value(context)
      end

      def repr
        "(#{left.repr} OR #{right.repr})"
      end
    end
  end
end
