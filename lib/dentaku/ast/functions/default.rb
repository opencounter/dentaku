require 'dentaku/ast/function'

module Dentaku
  module AST
    class Default < Function
      def self.type_syntax
        "default(%a, %a) = %a"
      end

      def initialize(expr, default_value)
        @expr = expr
        @default_value = default_value
      end

      def value
        @expr.evaluate
      rescue UnboundVariableError
        raise if Calculator.current.partial_eval?

        @default_value.evaluate
      end

      def cachable?
        false
      end
    end
  end
end

Dentaku::AST::Function.register_class(Dentaku::AST::Default)
