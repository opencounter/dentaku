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

      def _dump
        checksum # temp hack to add temp var
        super
      end

      def dependencies(context={})
        []
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
        "(TODO #{self.class.name})"
      end

      def inspect
        "<AST #{repr}>"
      end

      def source
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
        @checksum ||= Zlib.crc32(source)
      end

      # Do I need to care about where a value comes from?
      #
      # Need to cache full value metadata at every node, but return the value, except for the top level
      # where we want to also get the satisifed and unsatidfied identifiers
      #
      def evaluate
        if cachable?
          Calculator.current.cache do |cache|
            cache.getset(self, context) do |tracer|
              value_with_trace(tracer)
            end
            # [node_id, "Node", value]
            # [value_type, value, met_deps, unmet_deps]
          end
        else
          value
        end
      end

      def value_with_trace(trace)
        value
      end

      def cachable?
        true
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
