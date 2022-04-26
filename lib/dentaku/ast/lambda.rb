require_relative 'node'

module Dentaku
  module AST
    class Lambda < Node
      attr_reader :arguments, :body
      def initialize(arguments, body)
        # list of strings
        @arguments = arguments

        # another node
        @body = body
      end

      def repr
        "(#{@arguments.join(" ")} => #{@body.repr})"
      end
    end
  end
end
