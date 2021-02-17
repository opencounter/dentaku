require 'dentaku/ast/function'

module Dentaku
  module AST
    class Default < Function
      def self.type_syntax
        "default(%a, %a) = %a"
      end

      def initialize(identifier, default_value)
        super
        @identifier = identifier
        @default_value = default_value
      end

      def value
        @identifier.evaluate do
          @default_value.evaluate
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
