require_relative "./exploded_order"
require_relative "./shopify_api"
require_relative "./rollbar"

module BubbleSort
  ZINE_NAMES = [
    "how do calculators even zine",
    "bubble sort and other sorts zine",
    "cache cats dot biz zine",
    "secret messages zine",
    "how does the internet zine",
    "literal twitter bot zine",
    "hip hip array zine",
    "the nuts and bolts of machine learning zine",
    "smooth operator zine",
    "pixel perfect zine",
    "e_cute_overflow zine",
    "oh the things you can do with cs, woohoo! zine",
  ]
  VARIANT_COUNT = {1218878945=>(6..11), 1195972389=>(0..5), 1342622465=>(0..11)}
  VARIANT_ZINES = VARIANT_COUNT.map{|id, range| [id, ZINE_NAMES[range]] }.to_h

  def self.with_retry
    default_retry = 60
    retried = false

    begin
      yield
      retried = false
    rescue ActiveResource::ConnectionError, ActiveResource::ServerError,
      ActiveResource::ClientError, SocketError => ex
      puts "Request failed!\n#{ex.class}: #{ex.message}"
      unless retried
        header_retry = ex.respond_to?(:response) && ex.response['Retry-After']
        retry_after = (header_retry || default_retry).to_i
        puts "Retrying request in #{retry_after} seconds..."
        sleep(retry_after)
        retried = true
        retry
      else
        raise ex
      end
    end
  end

  def self.zines_since(last_processed_id)
    zines_to_order = []
    ShopifyAPI::Order.find_all(since_id: last_processed_id) do |sub|
      next if sub.tags.include?("subscription")

      with_retry do
        sub.tags = "store"
        sub.save
      end

      sub.line_items.each do |li|
        next unless VARIANT_ZINES.has_key?(li.variant_id)
        names = VARIANT_ZINES[li.variant_id]
        zines_to_order.push(
          email: sub.email,
          quantity: li.quantity,
          zines: names,
          shipping_address: sub.shipping_address.attributes,
          note: sub.note,
          number: sub.name,
          id: sub.id
        )
      end
    end

    zines_to_order
  end

  def self.create_order(to_order)
    to_order[:zines].each do |title|
      puts "Creating exploded order of #{title} for #{to_order[:email]} from order #{to_order[:number]}"
      ShopifyAPI::Order.create(
        email: to_order[:email],
        financial_status: "paid",
        shipping_address: to_order[:shipping_address],
        note: "From order #{to_order[:number]}. Note: #{to_order[:note]}",
        tags: "subscription",
        line_items: [{
          quantity: to_order[:quantity],
          title: title,
          price: 15.00,
          requires_shipping: true,
          grams: 114,
        }]
      )
    end
  end

  def self.explode_orders!
    eo = ExplodedOrder.order(:shopify_id).last
    last_processed_id = eo.nil? ? 1 : eo.shopify_id

    zines_since(last_processed_id).each do |subscription|
      with_retry { create_order(subscription) }
      ExplodedOrder.create!(shopify_id: subscription[:id])
    end
  rescue Exception => e
    Rollbar.error(e)
    raise(e)
  end

end
