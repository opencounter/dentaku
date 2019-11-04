module Dentaku
  module AST
    class List < Node
      def self.arity
        nil
      end

      def initialize(*elements)
        @elements = elements
      end

      def children
        @elements
      end

      def value
        @elements.map { |el| el.evaluate }
      end

      def dependencies(context={})
        @elements.flat_map { |val| val.dependencies(context) }
      end

      def generate_constraints(context)
        element_type = Type::Expression.make_variable('el')
        context.add_constraint!([:syntax, self], [:param, :list, [element_type]], [:literal, self])
        @elements.each_with_index do |el, i|
          el.generate_constraints(context)
          context.add_constraint!([:syntax, el], element_type, [:list_member, self, i])
        end
      end

      def repr
        "[#{@elements.map(&:repr).join(', ')}]"
      end

      def cachable?
        !@elements.empty? && @elements.all?(&:cachable?)
      end
    end
  end
end
