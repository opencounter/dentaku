require_relative './operation'

module Dentaku
  module AST
    class Combinator < Operation
      def initialize(*)
        super
        fail "#{ self.class } requires logical operands" unless valid_node?(left) && valid_node?(right)
      end

      def type
        :logical
      end

      def types
        [:bool, :bool, :bool]
      end

      private

      def valid_node?(node)
        node.dependencies.any? || node.type == :logical
      end
    end

    class And < Combinator
      def value(context={})
        left.value(context) && right.value(context)
      end

      def pretty_print
        "(#{left.pretty_print} AND #{right.pretty_print})"
      end
    end

    class Or < Combinator
      def value(context={})
        left.value(context) || right.value(context)
      end

      def pretty_print
        "(#{left.pretty_print} OR #{right.pretty_print})"
      end
    end
  end
end
