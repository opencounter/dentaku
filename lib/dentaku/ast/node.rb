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

      def full_original_source
        skeletons.first.first_token.original
      end

      def original_source
        full_original_source && loc_range.slice(full_original_source)
      end

      def index_range
        loc_range.index_range
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

      def partial_cache
        Calculator.current.partial_cache
      end

      def partial_cache_key
        self.object_id
      end

      def evaluate
        cached = partial_cache[partial_cache_key]
        return cached unless cached.nil?

        value
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
        if partial_cache.key?(partial_cache_key)
          return partial_cache[partial_cache_key]
        end

        partial_cache[partial_cache_key] = Calculator.current.with_partial do
          evaluate
        end
      rescue Missing
        partial_cache[partial_cache_key] = nil
      end

      def context
        Calculator.current
      end

      protected

      def value
        raise 'abstract'
      end

    end
  end
end
