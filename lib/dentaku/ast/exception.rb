module Dentaku
  module AST
    class ExceptionNode < Node

      def initialize(exp)
        @exception = exp
      end

      def value
        raise @exception
      end

      def literal?
        true
      end
    end
  end
end
