require 'dentaku/ast/function'

module Dentaku
  module AST
    class If < Function
      attr_reader :predicate, :left, :right

      def self.type_syntax
        "if(:bool, %a, %a) = %a"
      end

      def initialize(predicate, left, right)
        super
        @predicate = predicate
        @left      = left
        @right     = right
      end

      def value
        predicate.evaluate ? left.evaluate : right.evaluate
      end

      def dependencies(context={})
        # TODO : short-circuit?
        (predicate.dependencies(context) + left.dependencies(context) + right.dependencies(context)).uniq
      end
    end
  end
end

Dentaku::AST::Function.register_class(Dentaku::AST::If)
