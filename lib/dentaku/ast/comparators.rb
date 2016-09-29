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

    class NotEqual < Comparator
      def value
        left.evaluate != right.evaluate
      end

      def operator
        :!=
      end
    end

    class Equal < Comparator
      def value
        left.evaluate === right.evaluate
      end

      def operator
        :===
      end
    end
  end
end
