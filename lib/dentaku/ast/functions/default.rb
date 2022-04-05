require 'dentaku/ast/function'

module Dentaku
  module AST
    class Default < Function
      def self.type_syntax
        "default(%a, %a) = %a"
      end

      def initialize(*)
        super
        @expr, @default_value = @args
      end

      def value
        return @expr.evaluate if Calculator.current.partial_eval?

        begin
          @expr.evaluate
        rescue Missing
          @default_value.evaluate
        end
      end
    end
  end
end

Dentaku::AST::Function.register_class(Dentaku::AST::Default)
