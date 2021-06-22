require_relative 'operation'

module Dentaku
  module AST
    class Combinator < Operation
      def types
        [:bool, :bool, :bool]
      end

      def compute_both
        raise 'abstract'
      end

      def short_circuit_value
        raise 'abstract'
      end

      # [jneen] this method implements "branch favoring".
      # this means that we are not concerned with missing variables in sides
      # of the expression that don't matter. In essence, it allows us to
      # short-circuit from both sides of AND and OR expressions, so that we
      # don't demand data from users that is not necessary to evaluate the
      # expression logically.
      #
      # NOTE: the result of partial eval is true/false/nil
      def value
        return short_circuit_value if left.partial_evaluate == short_circuit_value
        return short_circuit_value if right.partial_evaluate == short_circuit_value
        compute_both
      end

      # [jneen]
      # if we are *currently* within a partial-eval context, we don't want
      # to kick of other partial-evaluations, but instead we should act as
      # if we are doing a normal evaluation. there should already be a `rescue`
      # block active to catch any UnboundVariableError's.
      def partial_evaluate
        return compute_both if Calculator.current.partial_eval?

        super
      end
    end

    class And < Combinator
      def short_circuit_value
        false
      end

      def compute_both
        left.evaluate && right.evaluate
      end

      def operator
        :AND
      end
    end

    class Or < Combinator
      def short_circuit_value
        true
      end

      def compute_both
        left.evaluate || right.evaluate
      end

      def operator
        :OR
      end
    end
  end
end
