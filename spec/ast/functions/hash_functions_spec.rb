require 'spec_helper'
require 'dentaku/ast/functions/hash'

describe 'HASH()' do
  it 'generates JSON from empty array' do
    expect(Dentaku("HASH([])")).to eq({}.to_json)
  end

  it 'generates JSON from 1D or 2D arrays' do
    expected_json = {"open" => "counter", "is" => "great"}.to_json
    [
      "HASH(['open', 'counter', 'is', 'great'])",
      "HASH([['open', 'counter'], ['is', 'great']])"
    ].each do |formula|
      expect(Dentaku(formula)).to eq expected_json
    end
  end
end

describe 'GET()' do

  let(:hash) { "HASH(['open', 'counter'])" }

  it 'gets present elements' do
    expect(Dentaku("GET(#{hash}, 'open')")).to eq 'counter'
  end

  it 'returns false with absent elements' do
    expect(Dentaku("GET(#{hash}, 'OPEN')")).to be false
  end
end

describe 'FETCH()' do

  let(:hash) { "HASH(['open', 'counter'])" }

  it 'gets present elements' do
    expect(Dentaku("FETCH(#{hash}, 'open', 'FALLBACK')")).to eq 'counter'
  end

  it 'returns the fallback for absent elements' do
    expect(Dentaku("FETCH(#{hash}, 'OPEN', 'FALLBACK')")).to eq 'FALLBACK'
  end
end


describe 'KEY()' do

  let(:hash) { "HASH(['open', 'counter'])" }

  it 'acts like Hash#key?' do
    expect(Dentaku("KEY(#{hash}, 'open')")).to be true
    expect(Dentaku("KEY(#{hash}, 'counter')")).to be false
  end
end

describe 'VALUE()' do

  let(:hash) { "HASH(['open', 'counter'])" }

  it 'acts like Hash#value?' do
    expect(Dentaku("VALUE(#{hash}, 'open')")).to be false
    expect(Dentaku("VALUE(#{hash}, 'counter')")).to be true
  end
end
