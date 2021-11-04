module Dentaku
  module AST
    class Struct < Node
      def self.arity
        nil
      end

      def initialize(*args)
        raise ParseError.new("Mismatched struct: #{args.map(&:value)}") unless args.length%2 == 0
        raise ParseError.new("Values without keys: #{args.compact.map(&:inspect)}") if args.any?(&:nil?)

        @keys = args.each_slice(2).map { |(k, v)| k }
        @struct = args.each_slice(2).each_with_object({}) do |(key, value), memo|
          memo[key.value] = value
        end
      end

      def children
        @keys + @struct.values
      end

      def value
        Hash[@struct.map {|k,v| [k, v.evaluate]}]
      end

      def dependencies(context={})
        @struct.values.flat_map { |val| val.dependencies(context) }
      end

      def generate_constraints(context)
        keys = @struct.keys.sort
        key_vars = keys.map do |key|
          Type::Expression.make_variable(key.to_sym)
        end

        context.add_constraint!([:syntax, self], [:struct, keys, key_vars], [:literal, self])
        keys.zip(key_vars) do |key, key_var|
          context.add_constraint!([:syntax, @struct[key]], key_var, [:struct_key, self, key])
          @struct[key].generate_constraints(context)
        end
      end

      def repr
        "{#{@struct.map { |k,v| "#{k}: #{v.repr}" }.join(', ')}}"
      end
    end
  end
end
