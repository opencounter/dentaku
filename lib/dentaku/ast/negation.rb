module Dentaku
  module AST
    class Negation < Operation
      attr_accessor :begin_token

      def initialize(node)
        @node = node
      end

      def children
        [@node]
      end

      def value
        @node.evaluate * -1
      end

      # used only for repr purposes
      def operator
        '-'
      end

      def generate_constraints(context)
        context.add_constraint!([:syntax, self], [:concrete, :numeric], [:operator, self, :return])
        context.add_constraint!([:syntax, @node], [:concrete, :numeric], [:operator, self, :left])
        @node.generate_constraints(context)
      end

      def repr
        "(- #{@node.repr})"
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
