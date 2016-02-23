module Dentaku
  module AST
    class List
      def self.arity
        nil
      end

      def initialize(*elements)
        @elements = elements
      end

      def value(context={})
        @elements.map { |el| el.value(context) }
      end

      def type
        :list
      end

      def dependencies(context={})
        @elements.flat_map { |val| val.dependencies(context) }
      end
    end
  end
end
