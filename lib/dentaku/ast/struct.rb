module Dentaku
  module AST
    class Struct < Node
      def self.arity
        nil
      end

      def initialize(*args)
        @keys = args.map(&:first)

        @struct = {}
        args.each do |(k, v)|
          @struct[k] = v
        end
      end

      def children
        @struct.values
      end

      def value
        Hash[@struct.map {|k,v| [k, v.evaluate]}]
      end

      def generate_constraints(context)
        keys = @keys.sort
        key_vars = keys.map do |key|
          Type::Expression.make_variable(key.to_sym)
        end

        keys.each do |key|
          @struct[key].generate_constraints(context)
        end

        return unless @struct.values.all?(&:valid?)

        context.add_constraint!([:syntax, self], [:struct, keys, key_vars], [:literal, self])
        keys.zip(key_vars) do |key, key_var|
          context.add_constraint!([:syntax, @struct[key]], key_var, [:struct_key, self, key])
        end
      end

      def repr
        "{#{@struct.map { |k,v| "#{k}: #{v.repr}" }.join(', ')}}"
      end
    end
  end
end
