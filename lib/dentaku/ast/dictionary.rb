module Dentaku
  module AST
    class Dictionary < Node
      def self.arity
        nil
      end

      def initialize(*args)
        raise RuntimeError.new("Mismatched dictionary") unless args.length%2 == 0
        @dictionary = args.each_slice(2).each_with_object({}) do |(key, value), memo|
          memo[key.value] = value
        end
      end

      def children
        @dictionary.keys + @dictionary.values
      end

      def value
        Hash[@dictionary.map {|k,v| [k, v.evaluate]}]
      end

      def simplify
        simplified_dict = @dictionary.map {|k,v| [k, v.simplify]}.to_h

        if simplified_dict.values.all? {|c| c.children.empty?}
          make_literal(simplified_dict.map {|k,v| [k,v.value]}.to_h)
        else
          ret = self.class.new()
          ret.instance_variable_set(:@dictionary, simplified_dict)
          ret
        end
      end

      def dependencies(context={})
        @dictionary.values.flat_map { |val| val.dependencies(context) }
      end

      def generate_constraints(context)
        keys = @dictionary.keys.sort
        key_vars = keys.map do |key|
          Type::Expression.make_variable(key.to_sym)
        end

        context.add_constraint!([:syntax, self], [:dictionary, keys, key_vars], [:literal, self])
        keys.zip(key_vars) do |key, key_var|
          context.add_constraint!([:syntax, @dictionary[key]], key_var, [:dictionary_key, self, key])
          @dictionary[key].generate_constraints(context)
        end
      end

      def repr
        "{#{@dictionary.map { |k,v| "#{k}: #{v.repr}" }.join(', ')}}"
      end
    end
  end
end
