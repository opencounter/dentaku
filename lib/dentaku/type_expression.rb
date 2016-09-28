require 'dentaku/variant'

module Dentaku
  class TypeExpression < Variant
    variants(
      syntax: [:ast],
      param: [:name, :arguments],
      dictionary: [:keys, :types],
      variable: [:name, :uniq],
      var: [:name],
    )

    def self.concrete(name)
      param(name, [])
    end

    def self.uniq
      @uniq_counter ||= 0
      @uniq_counter += 1
    end

    def self.make_variable(name)
      variable(name, uniq)
    end

    def map(&blk)
      cases(
        param: ->(name, arguments) {
          TypeExpression.param(name, arguments.map(&blk))
        },
        dictionary: ->(keys, types) {
          TypeExpression.dictionary(keys, types.map(&blk))
        },
        other: self
      )
    end

    def resolve_vars(scope={})
      cases(
        var: ->(name) {
          scope[name] ||= TypeExpression.variable(name, self.class.uniq)
        },
        other: -> { map { |x| x.resolve_vars(scope) } },
      )
    end

    def inspect
      "<TypeExpression #{pretty_print}>"
    end

    def pretty_print
      cases(
        syntax: ->(ast) { "[#{ast.pretty_print}]" },
        param: ->(name, arguments) {
          if arguments.empty?
            ":#{name}"
          else
            ":#{name}(#{arguments.map(&:pretty_print).join(' ')})"
          end
        },
        variable: ->(name, uniq) { "%#{name}#{uniq}" },
      )
    end

  end
end
