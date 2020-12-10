require_relative '../function'

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

      def cachable?
        false
      end
    end
  end
end

Dentaku::AST::Function.register_class(Dentaku::AST::Default)