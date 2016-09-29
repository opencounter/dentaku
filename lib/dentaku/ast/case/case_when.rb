module Dentaku
  module AST
    class CaseWhen < Operation
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
    end
  end
end
