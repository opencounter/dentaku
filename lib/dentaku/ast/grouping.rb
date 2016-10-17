module Dentaku
  module AST
    class Grouping < Node
      def initialize(node)
        @node = node
      end

      def children
        [@node]
      end

      def value
        @node.evaluate
      end

      def dependencies(context={})
        @node.dependencies(context)
      end

      def generate_constraints(context)
        @node.generate_constraints(context)
      end

      def repr
        "(#{@node.repr})"
      end
    end
  end
end
