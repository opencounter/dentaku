require_relative './operation'

module Dentaku
  module AST
    class Comparator < Operation
      def self.precedence
        5
      end

      def types
        [:numeric, :numeric, :bool]
      end
    end

    class LessThan < Comparator
      def value
        left.evaluate < right.evaluate
      end

      def operator
        :<
      end
    end

    class LessThanOrEqual < Comparator
      def value
        left.evaluate <= right.evaluate
      end

      def operator
        :<=
      end
    end

    class GreaterThan < Comparator
      def value
        left.evaluate > right.evaluate
      end

      def operator
        :>
      end
    end

    class GreaterThanOrEqual < Comparator
      def value
        left.evaluate >= right.evaluate
      end

      def operator
        :>=
      end
    end

    class Equality < Comparator
      def generate_constraints(context)
        ret_type = :bool
        var = Type::Expression.make_variable('a')

        context.add_constraint!([:syntax, self], [:concrete, ret_type], [:operator, self, :return])

        context.add_constraint!([:syntax, left], var, [:operator, self, :left])
        context.add_constraint!([:syntax, right], var, [:operator, self, :right])
        left.generate_constraints(context)
        right.generate_constraints(context)
      end
    end

    class NotEqual < Equality
      def value
        left.evaluate != right.evaluate
      end

      def operator
        :!=
      end
    end

    class Equal < Equality
      def value
        left.evaluate == right.evaluate
      end

      def operator
        :==
      end
    end
  end
end
