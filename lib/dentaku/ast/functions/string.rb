# join
Dentaku::AST::Function.register(
  'join([:string], :string) = :string', ->(strings, separator) {
    strings.join(separator)
  }
)

# split
Dentaku::AST::Function.register(
  'split(:string, :string) = [:string]', ->(string, separator) {
    string.split(separator)
  }
)

# match?
# Important: use double-quoted strings for patterns involving escapes.
Dentaku::AST::Function.register(
  'match(:string, :string) = :bool', ->(string, pattern) {
    !string.match(Regexp.new(pattern)).nil?
  }
)

# empty?
Dentaku::AST::Function.register(
  'empty(:string) = :bool', ->(string) {
    string.empty?
  }
)

# blank?
# From ActiveSupport
# https://github.com/rails/rails/blob/d66e7835bea9505f7003e5038aa19b6ea95ceea1/activesupport/lib/active_support/core_ext/object/blank.rb#L116
Dentaku::AST::Function.register(
  'blank(:string) = :bool', ->(string) {
    string.empty? || /\A[[:space:]]*\z/.match?(string)
  }
)
