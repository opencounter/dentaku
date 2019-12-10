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
        if left.any_dependencies_false?
          left.evaluate && right.evaluate
        elsif right.any_dependencies_false?
          right.evaluate && left.evaluate
        else
          left.evaluate && right.evaluate
        end
      end

      def repr
        "(#{left.repr} AND #{right.repr})"
      end
    end

    class Or < Combinator
      def value
        if left.any_dependencies_true?
          left.evaluate || right.evaluate
        elsif right.any_dependencies_true?
          right.evaluate || left.evaluate
        else
          left.evaluate || right.evaluate
        end
      end

      def repr
        "(#{left.repr} OR #{right.repr})"
      end
    end
  end
end
