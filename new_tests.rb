  def xp_allpaths(xp)
    parts = xp.split('/')
    rv    = []
    while !parts.empty?
      rv.push parts.join('/')
      parts.pop
    end
    rv
  end

  def get_attr(node, xpaths)
    attributes = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = Set.new}}
    xpaths.each do |raw_xpath|
      xp_allpaths(raw_xpath).each do |xp|
        next unless xp =~ /\S/
        next if attributes.has_key? xp
        node.xpath(xp).each do |n|
          n.attribute_nodes.each do |anode|
            attributes[xp][anode.name].add anode.value
          end
        end
      end
    end
    attributes
  end

  def controlled_attributes(attributes, max_size = 20)
    out = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = Set.new}}
    attributes.each_pair do |k, vh|
      vh.each_pair do |name, values|
        next if values.size > max_size
        out[k][name] = values.to_a
      end
    end
    out
  end

  def print_attributes(attr)
    attr.each_pair do |k, v|
      puts k
      v.each_pair do |name, values|
        puts "   #{name}: #{values.join(" | ")}"
      end
    end
  end
