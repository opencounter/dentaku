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
    end
  end
end
