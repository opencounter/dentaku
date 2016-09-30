module Dentaku
  module AST
    class CaseThen < Node
      attr_reader :node

      def repr
        "THEN #{@node.repr}"
      end

      def self.arity
        1
      end

      def initialize(node)
        @node = node
      end

      def value
        @node.evaluate
      end

      def dependencies(context={})
        @node.dependencies(context)
      end
    end
  end
end
