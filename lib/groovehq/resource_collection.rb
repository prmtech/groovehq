module GrooveHQ

  class ResourceCollection < Resource
    include Enumerable

    attr_reader :options

    def initialize(client, data, options = {})
      data = {} unless data.is_a?(Hash)
      data = data.with_indifferent_access

      @client = client

      meta_data = data.delete(:meta) { Hash.new }

      collection = Array(data.values.first).map do |item|
        Resource.new(client, item)
      end

      links = {}

      if meta_data.has_key?("pagination")
        links = {
          next: {
            href: meta_data["pagination"]["next_page"]
          },
          prev: {
            href: meta_data["pagination"]["prev_page"]
          }
        }
      end

      @data = OpenStruct.new(meta: meta_data, collection: collection)
      @rels = parse_links(links)
      @options = options.with_indifferent_access
    end

    def each
      return enum_for(:each) unless block_given?

      collection.each { |item| yield item }

      rel = @rels[:next] or return self
      resource_collection = rel.get(@options.except(:page))
      resource_collection.each(&Proc.new)

      @data = OpenStruct.new(meta: resource_collection.meta,
                             collection: collection + resource_collection.collection)
      @rels = resource_collection.rels
    end

  end

end
