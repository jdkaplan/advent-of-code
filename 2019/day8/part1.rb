# frozen_string_literal: true

class Layer
  attr_reader :width, :height, :pixels
  def initialize(width, height, pixels)
    @width = width
    @height = height
    @pixels = pixels
  end

  def to_s
    s = String.new
    pixels.each_slice(@width) do |line|
      s << line.join('')
      s << "\n"
    end
    s
  end
end

class SpaceImage
  attr_reader :width, :height, :data

  def initialize(width, height, data)
    @width = width
    @height = height
    @data = data.strip.chars.map(&:to_i)
    raise ArgumentError, 'bad data' unless (@data.size % (@width * @height)).zero?
  end

  def layers
    return @layers unless @layers.nil?

    @layers = []
    @data.each_slice(@width * @height) do |layer|
      @layers << Layer.new(@width, @height, layer)
    end
    @layers
  end
end

input = File.read(File.join(__dir__, 'input'))
img = SpaceImage.new(25, 6, input)

target_layer = img.layers.min_by do |layer|
  layer.pixels.count(&:zero?)
end
ones = target_layer.pixels.count { |p| p == 1 }
twos = target_layer.pixels.count { |p| p == 2 }
puts ones * twos
