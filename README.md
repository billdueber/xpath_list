# XPathList -- show all the paths in an XML document or node

Lately, I've been working with XML documents that are both (a) complex/inconsistent enough that I don't know their structure and
(b) too long (or too numerous) to inspect by hand.

This tiny little gem exposes a couple functions that can:
* return all the examples of valid xpaths
* return, in order, the xpaths of the leaves of the document, without any text or comments

It's mostly to see what *kinds* of structures
are present. For example, I'm not interested in the fact that there are a zillion `/A/B/C` structures, but
I want a way to be alerted to the fact that there is at least one `/A/B/D/C`.

Note that this doesn't print out a tree of the document without the text (TODO?). 

## Example

Given an XML document `test/xml`:

```xml
<?xml version="1.0"?>
<A>
  <B>This is a B</B>
  <B>This is a B</B>
  <B>This is a B</B>
  <B>This is a B</B>
  <B>Another B
    <C>with a C in it</C>
  </B>
  <B>Another B
    <Cgroup>
      <C>with</C>
      <C>grouped</C>
      <C>C nodes</C>
    </Cgroup>
  </B>
  <D>Here's a D with <em>an embedded child</em></D>
  <E>And an E
    <D>...with a D
      <B>that contains a B, for some reason</B>
    </D>
  </E>
</A>

```

...you can see what all the valid paths are

```ruby
require 'awsome_print'
ap XPathList.xpaths(filename: 'test.xml')
# [
#   [0] "/A/B",
#   [1] "/A/B/C",
#   [2] "/A/B/Cgroup/C",
#   [3] "/A/D/em",
#   [4] "/A/E/D/B"
# ]
```


You can also just give it a single nokogiri node

```ruby
doc = Nokogiri::XML(File.open('test.xml', 'r:utf-8').read)
node = doc.at('/A/D')
ap XPathList.xpaths(node: node)
# [
#    [0] "D/em"
# ]
```

And if you really want to, you can just get all the paths 
in order as they appear in the document

```ruby
ap XPathList.all_xpaths(node: node)
# [
#   [0] "/A/B",
#   [1] "/A/B",
#   [2] "/A/B",
#   [3] "/A/B",
#   [4] "/A/B/C",
#   [5] "/A/B/Cgroup/C",
#   [6] "/A/B/Cgroup/C",
#   [7] "/A/B/Cgroup/C",
#   [8] "/A/D/em",
#   [9] "/A/E/D/B"
# ]

```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/billdueber/xpath_list. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the XmlStructure project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/billdueber/xml_structure/blob/master/CODE_OF_CONDUCT.md).
