module Dentaku
  module AST
    class Node
      # type annotation to be added later
      # by the type checker
      attr_accessor :type
      attr_accessor :begin_token
      attr_accessor :end_token

      def self.precedence
        0
      end

      def self.arity
        arity = instance_method(:initialize).arity
        arity < 0 ? nil : arity
      end

      # def marshal_dump(*)
      #   checksum # temp hack to add temp var

      #   instance_variables.inject({}) do |vars, attr|
      #     vars[attr] = instance_variable_get(attr)
      #     vars
      #   end
      # end

      def dependencies(context={})
        []
      end

      def any_dependencies_true?
        dependencies.any? do |dep|
          v, t = context[dep]
          v && (t != :default)
        end
      end

      def any_dependencies_false?
        dependencies.any? do |dep|
          v, t = context[dep]
          !v && !v.nil? && (t != :default)
        end
      end

      def constraints(context)
        generate_constraints(context)
        context.constraints
      end

      def loc_range
        return [] unless begin_token && end_token
        [begin_token.begin_location, end_token.end_location]
      end

      def index_range
        return nil unless begin_token && end_token
        (begin_token.index_range.begin..end_token.index_range.end)
      end

      def generate_constraints(context)
        raise "Abstract #{self.class.name}"
      end

      def children
        []
      end

      def each
        return enum_for(:each) unless block_given?

        yield self

        children.each do |child|
          child.each do |c|
            yield c
          end
        end
      end

      def leaves
        each.select { |c| c.children.empty? }
      end

      def repr
        raise RuntimeError, "Cant REPR #{self.class}"
        # "(TODO #{self.class.name})"
      end

      def inspect
        "<AST #{repr}>"
      end

      def source
        return repr

        @source ||= begin
          source_values = if begin_token == end_token
            [begin_token.raw_value]
          else
            [begin_token.raw_value] + children.map(&:source) + [end_token.raw_value]
          end

          source_values.flatten.join
        end
      end

      def checksum
        @checksum ||= Zlib.crc32(source).to_s
      end

      def evaluate
        if cachable?
          Calculator.current.cache_for(self) do |cache|
            cache.getset { |tracer| value }
          end
        else
          value
        end
      end

      def value_with_trace(trace)
        value
      end

      def cachable?
        Calculator.current.cache
      end

      def context
        Calculator.current.memory
      end

      protected

      def value
        raise 'abstract'
      end

    end
  end
end
