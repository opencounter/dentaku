require 'spec_helper'
require 'dentaku/ast/function'

describe 'custom functions' do
  it 'calculates enumerable functions' do
    [
      ['INCLUDE([1, 2], 1)', true ],
      ['AT([1, 2], 0)',      1    ],
      ['ANY([0])',           true ],
      ['ANY([])',            false],
      ['EMPTY([0])',         false],
      ['EMPTY([])',          true ],
      ['IN([1], [1, 2])',    true ],
      ['IN([1], [2, 3])',    false],
      ['INCLUDE(0..2, 1)',   true ],
      ['INCLUDE(0..2, 3)',   false]
    ].each do |formula, result|
      expect(Dentaku(formula)).to eq result
    end
  end

  it 'calculates string functions' do
    [
      ["JOIN(['W', 'A', 'L', 'E'], '.')", 'W.A.L.E'],
      ["SPLIT('ABBA', '')", %w(A B B A)],
      [
        'MATCH("20 Jun but not June 20th", "\d{1,2}\s{1}[A-Za-z]{3}")', true
      ],
      ["EMPTY('text')", false],
      ["EMPTY('')",     true],
      ["EMPTY(' ')",    false],
      ["BLANK(' ')",    true],
    ].each do |formula, result|
      expect(Dentaku(formula)).to eq result
    end
  end

  it 'calculates conversion functions' do
    expect(Dentaku("to_str(1)")).to eq "1"
    expect(Dentaku("to_int('1')")).to eq 1
  end

  # pending 'calculates date functions' do
  #   expect(Dentaku("PARSE_DATE(2008, 1, 20)")).to eq 1200805200
  # end

end
