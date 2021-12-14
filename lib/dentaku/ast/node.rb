module Dentaku
  module AST
    class Node
      # type annotation to be added later
      # by the type checker
      attr_accessor :type
      attr_accessor :skeletons

      def self.make(skels, *a)
        n = new(*a)
        n.skeletons = [skels].flatten(1)
        n
      end

      def loc_range
        Syntax::Tokenizer::LocRange.between(skeletons.first, skeletons.last)
      end

      def self.precedence
        0
      end

      def self.arity
        arity = instance_method(:initialize).arity
        arity < 0 ? nil : arity
      end

      def dependencies(context={})
        []
      end

      def valid?
        children.all?(&:valid?)
      end

      def satisfy_existing_dependencies
        existing_dependencies = context.keys & dependencies

        Calculator.current.cache_for(self) do |cache|
          cache.trace do |tracer|
            existing_dependencies.each do |dep|
              tracer.satisfied(dep)
            end
          end
        end
      end

      def constraints(context)
        generate_constraints(context)
        context.constraints
      end

      def generate_constraints(context)
        raise "Abstract #{self.class.name}"
      end

      def children
        []
      end

      def to_sexpr
        [self.class.name, loc_range, type && type.to_sexpr, *serialized_values]
      end

      def serialized_values
        []
      end

      def each(&b)
        return enum_for(:each) unless block_given?

        yield self

        children.each do |child|
          child.each(&b)
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
        if instance_variable_defined?(:@_partial) && !@_partial.nil?
          return @_partial
        end

        return value if Calculator.current.partial_eval? || !cachable?

        Calculator.current.cache_for(self) do |cache|
          cache.getset { |tracer| value }
        end
      end

      def cachable?
        Calculator.current.cache
      end

      # [jneen] this method allows us to evaluate a node without
      # raising UnboundVariableError or logging unbound identifiers.
      #
      # the purpose of this is to choose the correct path in AND/OR
      # expressions, so as to not report missing identifiers in branches
      # that do not matter to the expression.
      def partial_evaluate
        if instance_variable_defined?(:@_partial)
          return @_partial
        end

        @_partial = Calculator.current.with_partial do
          evaluate
        end
      rescue Missing
        @_partial = nil
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
