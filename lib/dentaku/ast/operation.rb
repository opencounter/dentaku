require_relative './node'

module Dentaku
  module AST
    class Operation < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left  = left
        @right = right
      end

      def dependencies(context={})
        (left.dependencies(context) + right.dependencies(context)).uniq
      end

      def types
        raise 'Abstract'
      end

      def operator
        raise 'Abstract'
      end

      def pretty_print
        "#{left.pretty_print} #{operator} #{right.pretty_print}"
      end

      def generate_constraints(context)
        left_type, right_type, ret_type = self.types

        context.add_constraint!([:syntax, self], [:concrete, ret_type], [:operator, self, :return])
        context.add_constraint!([:syntax, left], [:concrete, left_type], [:operator, self, :left])
        context.add_constraint!([:syntax, right], [:concrete, right_type], [:operator, self, :right])
        left.generate_constraints(context)
        right.generate_constraints(context)
      end

      def self.right_associative?
        false
      end
    end
  end
end
