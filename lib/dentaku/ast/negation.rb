module Dentaku
  module AST
    class Negation < Operation
      def initialize(node)
        @node = node
      end

      def value
        @node.value * -1
      end

      def generate_constraints(context)
        context.add_constraint!([:syntax, self], [:concrete, :bool], [:operator, self, :return])
        context.add_constraint!([:syntax, @node], [:concrete, :bool], [:operator, self, :left])
        @node.generate_constraints(context)
      end

      def repr
        "(! #{@node.repr})"
      end

      def self.arity
        1
      end

      def self.right_associative?
        true
      end

      def self.precedence
        40
      end

      def dependencies(context={})
        @node.dependencies(context)
      end
    end
  end
end
