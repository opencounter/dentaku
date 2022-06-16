module Dentaku
  module AST
    # [jneen] a node that represents a syntax error
    class Invalid < Node
      attr_reader :text, :children
      def initialize(text, *children)
        @text = text
        @children = children
      end

      def message
        "syntax error: #{@text}: #{original_source.inspect}"
      end

      def valid?
        false
      end

      def value
        raise "invalid: #{self.inspect}"
      end

      def dependencies(context={})
        @children.flat_map { |c| c.dependencies(context) }
      end

      def repr
        if @children.empty?
          "#ERR:#{message.inspect}"
        else
          "#ERR:#{message.inspect}(#{children.map(&:repr).join(', ')})"
        end
      end

      def generate_constraints(context)
        context.invalid_ast!(Type::ParseError, self)

        @children.each { |c| c.generate_constraints(context) }
      end
    end
  end
end
