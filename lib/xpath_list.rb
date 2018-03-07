require "xpath_list/version"
require 'nokogiri'

module XPathList
  # Only pay attention to named tags; ignore
  # text, comments, processing instructions, stylesheets
  VALID_TYPE = 1

  # Optionally ignore some tags (e.g., <em> or <i> or whatnot)
  DEFAULT_IGNORE_TAGS = []



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


  private

  def self.noko_load(filename)
    Nokogiri::XML(File.open(filename, 'r:utf-8').read)
  end


end
