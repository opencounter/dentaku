require_relative './operation'

module Dentaku
  module AST
    class Combinator < Operation
      def types
        [:bool, :bool, :bool]
      end
    end

    class And < Combinator
      def value
        # [jneen] this and the similar method below implement "branch favoring".
        # this means that we are not concerned with missing variables in sides
        # of the expression that don't matter. In essence, it allows us to
        # short-circuit from both sides of AND and OR expressions, so that we
        # don't demand data from users that is not necessary to evaluate the
        # expression logically.
        return false if left.partial_evaluate == false
        return false if right.partial_evaluate == false

        left.evaluate && right.evaluate
      end

      def repr
        "(#{left.repr} AND #{right.repr})"
      end
    end

    class Or < Combinator
      def value
        return true if left.partial_evaluate == true
        return true if right.partial_evaluate == true

        left.evaluate || right.evaluate
      end

      def repr
        "(#{left.repr} OR #{right.repr})"
      end
    end
  end
end
