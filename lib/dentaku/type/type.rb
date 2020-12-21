module Dentaku
  module Type
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
      )

      def repr
        cases(
          list: ->(member_type) { "[#{member_type.repr}]" },
          dictionary: ->(keys, types) {
            content = keys.zip(types).map { |(key, type)| "#{key}: #{type.repr}" }.join(', ')
            "{ #{content} }"
          },
          bound: ->(var_name) { "%#{var_name}" },
          other: -> { _name }
        )
      end

      def inspect
        "<type #{repr}>"
      end
    end
  end
end
