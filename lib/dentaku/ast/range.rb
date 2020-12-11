require_relative "./operation"

module Dentaku
  module AST
    class Range < Operation
      def types
        [:numeric, :numeric, :range]
      end

      # must return something responding to ===, in this case a
      # regular ruby Range.
      def value
        (left.value..right.value)
      rescue
        binding.pry
      end

      def generate_constraints!(context)
        # pass. this is handled by AST::Case
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
