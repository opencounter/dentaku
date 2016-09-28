module Dentaku
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
  end
end
