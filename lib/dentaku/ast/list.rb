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

      def generate_constraints(context)
        element_type = TypeExpression.make_variable('el')
        context.add_constraint!([:syntax, self], [:param, :list, element_type], [:literal, self])
        @elements.each_with_index do |el, i|
          el.generate_constraints(context)
          context.add_constraint!([:syntax, el], element_type, [:list_member, self, i])
        end
      end

      def pretty_print
        "[#{@elements.map(&:pretty_print).join(', ')}]"
      end
    end
  end
end
