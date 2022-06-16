require_relative "operation"

module Dentaku
  module AST
    class Range < Operation
      def types
        [:numeric, :numeric, :range]
      end

      # must return something responding to ===, in this case a
      # regular ruby Range.
      def value
        (left.evaluate..right.evaluate)
      end

      # for repr purposes only
      def operator
        '..'
      end

      def generate_constraints!(context)
        context.add_constraint!([:syntax, self], [:concrete, :range], [:literal, self])
        context.add_constraint!([:syntax, left], [:concrete, :numeric], [:range_element, self, :left])
        context.add_constraint!([:syntax, right], [:concrete, :numeric], [:range_element, self, :right])
      end

      # higher than comparators (5) lower than any kind of math (10+)
      def self.precedence
        8
      end

      def repr
        "#{left.repr}..#{right.repr}"
      end
    end
  end
end
