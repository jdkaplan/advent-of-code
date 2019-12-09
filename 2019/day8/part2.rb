# frozen_string_literal: true

class Layer
  attr_reader :width, :height, :pixels
  def initialize(width, height, pixels)
    @width = width
    @height = height
    @pixels = pixels
  end

  def get_pixel(r, c)
    @pixels[r * @width + c]
  end

  def to_s
    s = String.new
    pixels.each_slice(@width) do |line|
      s << line.join('')
      s << "\n"
    end
    s
  end

  def to_tty
    s = String.new
    pixels.each_slice(@width) do |row|
      line = row.map do |pixel|
        case pixel
        when 1
          # Unicode full block
          "\u2588"
        when 0
          ' '
        else
          raise ArgumentError, "Unexpected pixel value #{pixel}"
        end
      end
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

  def render
    pixels = []
    @height.times do |r|
      @width.times do |c|
        pixel = get_pixel(r, c)
        pixels << pixel
      end
    end
    Layer.new(@width, @height, pixels)
  end

  def get_pixel(r, c)
    layers.each do |layer|
      pixel = layer.get_pixel(r, c)
      return pixel if pixel != 2
    end
  end
end

input = File.read(File.join(__dir__, 'input'))
img = SpaceImage.new(25, 6, input)
puts img.render.to_tty
