module Dentaku
  module AST
    class Key < Node
      def initialize(token)
        @identifier = token.value.downcase.to_sym
      end

      def value
        @identifier
      end

      def repr
        self.class.name
      end
    end
  end
end
