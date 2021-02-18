module Dentaku
  module AST
    class Nil < Node
      def value
        nil
      end

      def generate_constraints(context)
        context.invalid_ast!(Type::Error::EmptyExpression, self)
      end
    end
  end
end
