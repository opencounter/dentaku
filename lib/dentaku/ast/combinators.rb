require_relative 'operation'

module Dentaku
  module AST
    class Combinator < Operation
      def types
        [:bool, :bool, :bool]
      end
    end

    class And < Combinator
      def partial_evaluate
        left_partial = left.partial_evaluate
        return false if left_partial == false

        right_partial = right.partial_evaluate
        return false if right_partial == false

        return nil if left_partial.nil? || right_partial.nil?
        true
      end

      def value
        # [jneen] this and the similar method below implement "branch favoring".
        # this means that we are not concerned with missing variables in sides
        # of the expression that don't matter. In essence, it allows us to
        # short-circuit from both sides of AND and OR expressions, so that we
        # don't demand data from users that is not necessary to evaluate the
        # expression logically.
        #
        # NOTE: need `== false` here because the result is true/false/nil
        partial = self.partial_evaluate

        return left.evaluate && right.evaluate if partial.nil?

        partial
      end

      def repr
        "(#{left.repr} AND #{right.repr})"
      end
    end

    class Or < Combinator
      def partial_evaluate
        left_partial = left.partial_evaluate
        return true if left_partial == true

        right_partial = right.partial_evaluate
        return true if right_partial == true

        return nil if left_partial.nil? || right_partial.nil?
        false
      end

      def value
        partial = self.partial_evaluate

        return left.evaluate || right.evaluate if partial.nil?

        partial
      end

      def repr
        "(#{left.repr} OR #{right.repr})"
      end
    end
  end
end
