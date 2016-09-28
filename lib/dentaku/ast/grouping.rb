module Dentaku
  module AST
    class Grouping < Node
      def initialize(node)
        @node = node
      end

      def value(context={})
        @node.value(context)
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
