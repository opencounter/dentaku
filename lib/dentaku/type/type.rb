module Dentaku
  module Type
    def self.build
      yield Type
    end

    class Type < Variant
      variants(
        bool: [],
        numeric: [],
        string: [],
        range: [],
        date: [],
        abstract: [],

        list: [:member_type],
        dictionary: [:keys, :types],
        bound: [:name],
      )

      def repr
        cases(
          list: ->(member_type) { "[#{member_type.repr}]" },
          dictionary: ->(keys, types) {
            content = keys.zip(types).map { |(key, type)| "#{key}: #{type.repr}" }.join(', ')
            "{ #{content} }"
          },
          bound: ->(var_name) { "%#{var_name}" },
          abstract: -> { '%unknown-type' },
          other: -> { ":#{_name}" },
        )
      end

      def to_expr
        cases(
          list: ->(el_type) { Expression.param(:list, [el_type.to_expr]) },
          dictionary: ->(keys, types) { Expression.dictionary(keys, types.map(&:to_expr)) },
          bound: ->(var_name) { Expression.make_variable(var_name) },
          abstract: -> { Expression.make_variable('abstract') },
          other: -> { Expression.concrete(_name) },
        )
      end

      def inspect
        "<type #{repr}>"
      end
    end
  end
end
