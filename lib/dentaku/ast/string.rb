require_relative "./literal"

module Dentaku
  module AST
    class String < Literal
      def value_type
        :string
      end
    end
  end
end
