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

        pair: [:left_type, :right_type],
        list: [:member_type],
        dictionary: [:keys, :types],

        bound: [:name],

        host: [:name, :arguments],
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
          host: ->(name, args) {
            n = "&#{name}"
            a = args.any? ? "(#{args.map(&:repr)})" : ""
            "#{n}#{a}"
          },
          other: -> { ":#{_name}" },
        )
      end

      def to_expr
        cases(
          list: ->(el_type) { Expression.param(:list, [el_type.to_expr]) },
          dictionary: ->(keys, types) { Expression.dictionary(keys, types.map(&:to_expr)) },
          bound: ->(var_name) { Expression.make_variable(var_name) },
          abstract: -> { Expression.make_variable('abstract') },
          host: ->(name, args) { Expression.param(name, args.map(&:to_expr)) },
          other: -> { Expression.concrete(_name) },
        )
      end

      def inspect
        "<type #{repr}>"
      end
    end
  end
end
