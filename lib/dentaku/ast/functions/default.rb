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
        if Calculator.current.partial_eval?
          @expr.evaluate
        else
          begin
            @expr.evaluate
          rescue Missing
            @default_value.evaluate
          end
        end
      end

      # Don't cache values, but still make a cache key so child identifiers are reported
      def evaluate
        Calculator.current.cache_for(self) do |cache|
          cache.trace do
            value
          end
        end
      end
    end
  end
end

Dentaku::AST::Function.register_class(Dentaku::AST::Default)
