# frozen_string_literal: true

Chemical = Struct.new(:amount, :name) do
  def pretty_print(pp)
    pp.text to_s
  end

  def to_s
    "#{amount} #{name}"
  end
end

Formula = Struct.new(:product, :reactants) do
  def produces?(name)
    product.name == name
  end

  def pretty_print(pp)
    pp.text to_s
  end

  def to_s
    "#{product} <= #{reactants.join(', ')}"
  end
end

def parse_chemical(text)
  parts = text.split(' ')
  amount = parts[0].to_i
  name = parts[1].strip
  Chemical.new(amount, name)
end

def parse(input)
  input.lines.map do |line|
    left, right = line.split('=>')

    product = parse_chemical(right)
    reactants = left.split(',').map { |text| parse_chemical(text) }
    Formula.new(product, reactants)
  end
end

def ore_needed(formulas, fuel)
  have = Hash.new { |hash, key| hash[key] = 0 }
  need = Hash.new { |hash, key| hash[key] = 0 }

  have = Hash.new { |hash, key| hash[key] = 0 }
  need = Hash.new { |hash, key| hash[key] = 0 }
  need['FUEL'] = fuel
  ore = 0

  until need.empty?
    product, amount = need.shift
    next if amount.zero?

    formula = formulas.find { |f| f.produces? product }

    needed = (amount - have[product])

    runs = (needed.fdiv formula.product.amount).ceil

    formula.reactants.each do |r|
      wanted = runs * r.amount
      already_have = have[r.name]
      can_use = [already_have, wanted].min
      more = wanted - can_use

      have[r.name] -= can_use
      if r.name == 'ORE'
        ore += more
      else
        need[r.name] += more
      end
    end

    yielded = runs * formula.product.amount
    extra = yielded - needed
    have[product] += extra
  end

  ore
end

class OreCalculator
  def initialize(formulas)
    @formulas = formulas
    @memo = {}
  end

  def calc(fuel)
    return @memo[fuel] if @memo.key?(fuel)

    ore = ore_needed(@formulas, fuel)
    @memo[fuel] = ore
    ore
  end
end

def binary_search(f, lo, hi, target)
  until (f.call(hi) - f.call(lo)).zero? || hi - lo < 2
    mid = (hi + lo) / 2
    case f.call(mid) <=> target
    when -1
      lo = mid
    when 0
      break
    when +1
      hi = mid
    end
  end

  lo
end

input = File.read(File.join(__dir__, 'input'))
formulas = parse(input)

available_ore = 1_000_000_000_000

upper_threshold = 0
upper_fuel = 1
until upper_threshold > available_ore
  upper_threshold = ore_needed(formulas, upper_fuel)
  upper_fuel *= 2
end

oc = OreCalculator.new(formulas)
fuel_made = binary_search(oc.method(:calc), 0, upper_fuel, available_ore)
puts fuel_made
