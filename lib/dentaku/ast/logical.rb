require_relative "./literal"

module Dentaku
  module AST
    class Logical < Literal
      def value_type
        :bool
      end
    end
  end
end
