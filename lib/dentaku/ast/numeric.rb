require_relative "literal"

module Dentaku
  module AST
    class Numeric < Literal
      def value_type
        :numeric
      end
    end
  end
end
