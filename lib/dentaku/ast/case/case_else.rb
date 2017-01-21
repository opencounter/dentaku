module Dentaku
  module AST
    class CaseElse < Node
      attr_reader :node

      def self.arity
        1
      end

      def initialize(node)
        @node = node
      end

      def children
        [@node]
      end

      def value
        @node.evaluate
      end

      def simplified_value
        self
      end

      def dependencies(context={})
        @node.dependencies(context)
      end
    end
  end
end
