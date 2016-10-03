require 'spec_helper'

describe Dentaku::Type::Variant do
  class Either < Dentaku::Type::Variant
    variants(
      left: [:left_val],
      right: [:right_val],
    )

    def compute
      self.cases(
        left: ->(val) { val + 1 },
        right: ->(val) { val - 1 },
      )
    end

  end

  it "runs" do
    left = Either.left(1)
    expect(left.left_val).to be(1)
    expect(left.compute).to be(2)

    right = Either.right(4)
    expect(right.right_val).to be(4)
    expect(right.compute).to be(3)
  end
end
