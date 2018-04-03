require_relative "xpath_list/version"
require 'nokogiri'
require 'forwardable'

module XPathList
  # Only pay attention to named tags; ignore
  # text, comments, processing instructions, stylesheets
  VALID_TYPE = 1

  # Optionally ignore some tags (e.g., <em> or <i> or whatnot)
  DEFAULT_IGNORE_TAGS = []

  class MinMax
    def initialize(min = nil, max = nil)
      @min = min
      @max = max
    end

    def min(v = nil)
      return @min if v.nil?
      @min = @min.nil? ? v : [@min, v].min
      @max ||= @min
      @min
    end

    def max(v = nil)
      return @max if v.nil?
      @max = @max.nil? ? v : [@max, v].max
      @min ||= @max
      @max
    end

    def <<(num)
      self.min(num)
      self.max(num)
      self
    end

    def merge(other)
      min = [@min, other.min].min
      max = [@max, other.max].max
      self.class.new(min, max)
    end

    def to_s
      if @max == @min
        @max
      else
        "#{@min}..#{max}"
      end
    end
  end

  class Arities
    extend Forwardable

    def_delegators :@arities, :each_pair, :keys, :has_key?, :empty?

    def initialize
      @arities = {}
    end

    alias_method :has_tag?, :has_key?

    def tags
      @arities.keys
    end


    def [](tag)
      @arities[tag]
    end

    def add(tag, num)
      @arities[tag] = if @arities[tag].nil?
                        MinMax.new(num, num)
                      else
                        @arities[tag] << num
                      end
      self

    end

    def to_s
      tags.map{|t| "#{t}[#{self[t].to_s}]"}.join(", ")
    end

    def merge(other)
      merged = self.class.new
      other.tags.each do |othertag|
        merged.add(othertag, other[othertag].min)
        merged.add(othertag, other[othertag].max)
      end
      (tags - other.tags).each do |mytag|
        merged.add(mytag, 0)
      end
      merged
    end
  end


  class XPathsWithArities

    extend Forwardable
    include Enumerable

    def_delegators :@xpaths_with_arities, :each, :each_pair

    def initialize
      @xpaths_with_arities = {}
    end

    def add(xpath, arities)
      @xpaths_with_arities[xpath] ||= Arities.new
      @xpaths_with_arities[xpath] = @xpaths_with_arities[xpath].merge(arities)
    end

  end


  class XPathArityNode
    attr_accessor :tag, :arity, :children, :arities

    def initialize(node:, ignore_tags: XPathList::DEFAULT_IGNORE_TAGS)
      @tag          = node.name
      kid_nokonodes = node.children.reject {|k| ignore_tags.include?(k.name) or k.type != VALID_TYPE}.to_a

      @arities = Arities.new

      kid_nokonodes.map(&:name).compact.uniq.each do |ktag|
        @arities.add(ktag, kid_nokonodes.count {|x| x.name == ktag})
      end
      @children = kid_nokonodes.map {|knn| self.class.new(node: knn, ignore_tags: ignore_tags)}

    end

    def all_xpaths_in_order
      return [tag] if children.empty?
      children.flat_map do |kid|
        kid.all_xpaths_in_order.map {|xs| tag + '/' + xs}
      end
    end

    def all_xpaths_in_order_with_arity
      return [[tag, arities]] if children.empty?
      children.flat_map do |kid|
        kid.all_xpaths_in_order_with_arity.map {|xs| [tag + '/' + xs.first, xs.last]}
      end.unshift([tag, arities])
    end

    def all_xpaths
      all_xpaths_in_order.uniq.sort
    end

    def all_xpaths_with_arity
      xpa = XPathsWithArities.new
      rv = {}
      all_xpaths_in_order_with_arity.each do |xpath, arities|
        xpa.add(xpath, arities)
        rv[xpath] ||= {}

        arities.each_pair do |tag, mm|
          rv[xpath][tag] ||= MinMax.new
          rv[xpath][tag].min(mm.min)
          rv[xpath][tag].max(mm.max)
        end

        (rv[xpath].keys - arities.tags).each do |tag|
          rv[xpath][tag].min(0) unless arities.has_tag?(tag)
        end
      end
      # rv
      xpa
    end

  end


  def self.all_xpaths(filename: nil, node: nil, ignore_tags: DEFAULT_IGNORE_TAGS)
    node ||= noko_load(filename)
    tag  = node.name
    kids = node.children.reject {|k| ignore_tags.include? k.name or k.type != VALID_TYPE}

    # Special case for the root node, 'document'
    display_tag = tag == 'document' ? '' : tag


    # base case: no kids. Just return an array with the tag
    return [tag] if kids.size == 0

    # otherwise, prepend this tag onto the strings returned by the next
    # level down

    kids.flat_map do |k|
      all_xpaths(node: k, ignore_tags: ignore_tags).map {|xs| display_tag + '/' + xs}
    end
  end

  def self.xpaths(filename: nil, node: nil, ignore_tags: DEFAULT_IGNORE_TAGS)
    all_xpaths(filename: filename, node: node, ignore_tags: ignore_tags).uniq.sort
  end

  # Let's do it again, but this time keep track of arities
  def self.all_xpaths_with_arities(filename: nil, node: nil, ignore_tags: DEFAULT_IGNORE_TAGS)
    node ||= noko_load(filename)

    tag = node.name
    # Special case for the root node, 'document'
    display_tag = tag == 'document' ? '' : tag

    xpn = XPathNode.new(display_tag)

    kidnodes     = node.children.reject {|k| ignore_tags.include? k.name or k.type != VALID_TYPE}
    xpn.children = kidnodes.map {|kn| XPathNode.new(kn.name)}


  end


  private

  def self.noko_load(filename)
    Nokogiri::XML(File.open(filename, 'r:utf-8').read)
  end


end
