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

input = File.read(File.join(__dir__, 'input'))
formulas = parse(input)

have = Hash.new { |hash, key| hash[key] = 0 }
need = Hash.new { |hash, key| hash[key] = 0 }
need['FUEL'] = 1
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
puts ore
