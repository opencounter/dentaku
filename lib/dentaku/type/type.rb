module Dentaku
  module Type
    def self.build
      yield Type
    end

    class Type < Variant
      variants(
        declared: [:declared],
        dictionary: [:keys, :types],
        abstract: [],
        bound: [:name],
      )

      def repr
        cases(
          declared: ->(decl) { decl.repr },
          dictionary: ->(keys, types) {
            content = keys.zip(types).map { |(key, type)| "#{key}: #{type.repr}" }.join(', ')
            "{ #{content} }"
          },
          bound: ->(var_name) { "%#{var_name}" },
          abstract: -> { '%unknown-type' },
        )
      end

      def to_expr
        cases(
          declared: ->(decl) { Expression.param(decl.type_name, decl.args.map(&:to_expr)) },
          dictionary: ->(keys, types) { Expression.dictionary(keys, types.map(&:to_expr)) },
          bound: ->(var_name) { Expression.make_variable(var_name) },
          abstract: -> { Expression.make_variable('abstract') },
        )
      end

      def inspect
        "<type #{repr}>"
      end
    end
  end
end
