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

  let(:left) { Either.left(1) }
  let(:right) { Either.right(2) }

  it "creates predicates" do
    expect(left.left?).to be(true)
    expect(left.right?).to be(false)

    expect(right.left?).to be(false)
    expect(right.right?).to be(true)
  end

  it "creates readers" do
    expect(left.left_val).to be(1)
    expect(right.right_val).to be(2)
  end

  it "dispatches on case" do
    expect(left.compute).to be(2)
    expect(right.compute).to be(1)
  end

  it "creates from sexpr" do
    either = Either.from_sexpr([:left, [:right, 4]])
    expect(either.left?).to be(true)
    expect(either.left_val.right?).to be(true)
    expect(either.left_val.right_val).to be(4)
  end
end
