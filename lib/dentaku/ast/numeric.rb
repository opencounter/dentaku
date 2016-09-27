require_relative "./literal"

module Dentaku
  module AST
    class Numeric < Literal
      def generate_constraints(context)
        context.add_constraint!([:syntax, self], [:concrete, :numeric], [:literal, self])
      end
    end
  end
end
