module Dentaku
  module AST
    class CaseSwitchVariable < Node
      attr_reader :node

      def initialize(node)
        @node = node
      end

      def value
        @node.value
      end

      def dependencies(context={})
        @node.dependencies(context)
      end

      def self.arity
        1
      end
    end
  end
end
