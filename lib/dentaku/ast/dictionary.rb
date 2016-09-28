module Dentaku
  module AST
    class Dictionary
      def self.arity
        nil
      end

      def initialize(*args)
        raise RuntimeError.new("Mismatched dictionary") unless args.length%2 == 0
        @dictionary = args.each_slice(2).each_with_object({}) do |(key, value), memo|
          memo[key.value] = value
        end
      end

      def value(context={})
        Hash[@dictionary.map {|k,v| [k, v.value(context)]}]
      end

      def type
        :dictionary
      end

      def dependencies(context={})
        @dictionary.values.flat_map { |val| val.dependencies(context) }
      end

      def generate_constraints(context)
        keys = @dictionary.keys.sort
        key_vars = keys.map do |key|
          TypeExpression.make_variable(key.to_sym)
        end

        context.add_constraint!([:syntax, self], [:dictionary, keys, key_vars], [:literal, self])
        keys.zip(key_vars) do |key, key_var|
          context.add_constraint!([:syntax, @dictionary[key]], key_var, [:dictionary_key, self, key])
          @dictionary[key].generate_constraints(context)
        end
      end

      def pretty_print
        "{#{@dictionary.map { |k,v| "#{k}: #{v.pretty_print}" }.join(', ')}}"
      end
    end
  end
end
