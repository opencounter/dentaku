require_relative "literal"

module Dentaku
  module AST
    class Range < Literal
      def value_type
        :range
      end
    end
  end
end
