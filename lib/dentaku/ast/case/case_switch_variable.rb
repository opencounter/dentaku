module Dentaku
  module AST
    class CaseSwitchVariable < Node
      attr_reader :node

      def repr
        "CASE SWITCH(#{@node.repr})"
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

      def self.arity
        1
      end
    end
  end
end
