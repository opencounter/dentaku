module Dentaku
  module AST
    class CaseWhen < Node
      attr_reader :node

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

      def repr
        "WHEN #{node.repr}"
      end
    end
  end
end
