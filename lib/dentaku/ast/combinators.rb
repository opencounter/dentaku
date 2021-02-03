require_relative 'operation'

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
          left.satisfy_existing_dependencies
          right.evaluate && left.evaluate
        else
          left.evaluate && right.evaluate
        end
      end

      def operator
        :AND
      end
    end

    class Or < Combinator
      def value
        if left.any_dependencies_true?
          left.evaluate || right.evaluate
        elsif right.any_dependencies_true?
          left.satisfy_existing_dependencies
          right.evaluate || left.evaluate
        else
          left.evaluate || right.evaluate
        end
      end

      def operator
        :OR
      end
    end
  end
end
