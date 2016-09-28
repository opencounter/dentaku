require_relative './operation'

module Dentaku
  module AST
    class Comparator < Operation
      def self.precedence
        5
      end

      def type
        :logical
      end

      def types
        [:numeric, :numeric, :bool]
      end
    end

    class LessThan < Comparator
      def value(context={})
        left.value(context) < right.value(context)
      end

      def operator
        :<
      end
    end

    class LessThanOrEqual < Comparator
      def value(context={})
        left.value(context) <= right.value(context)
      end

      def operator
        :<=
      end
    end

    class GreaterThan < Comparator
      def value(context={})
        left.value(context) > right.value(context)
      end

      def operator
        :>
      end
    end

    class GreaterThanOrEqual < Comparator
      def value(context={})
        left.value(context) >= right.value(context)
      end

      def operator
        :>=
      end
    end

    class NotEqual < Comparator
      def value(context={})
        left.value(context) != right.value(context)
      end

      def operator
        :!=
      end
    end

    class Equal < Comparator
      def value(context={})
        left.value(context) === right.value(context)
      end

      def operator
        :===
      end
    end
  end
end
