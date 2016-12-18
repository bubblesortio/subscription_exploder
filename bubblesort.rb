require_relative "./exploded_orders"
require_relative "./shopify_api"

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

  def self.zines_since(last_id)
    zines_to_order = []
    ShopifyAPI::Order.find_all(since_id: last_order_id).each do |sub|
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

  def self.create_orders(zines_to_order)
    zines_to_order.each do |to_order|
      to_order[:zines].each do |title|
        to_order = zines_to_order.first
        title = to_order[:zines].first
        ShopifyAPI::Order.create(
          email: to_order[:email],
          financial_status: "paid",
          shipping_address: to_order[:shipping_address],
          note: "From order #{to_order[:number]}. Note: #{to_order[:note]}",
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
  end

  def self.explode_orders!
    last_processed_id = ExplodedOrders.order("shopify_id DESC").last.shopify_id
    zines_to_order = zines_since(last_processed_id)
    ExplodedOrders.create!(shopify_id: zines_to_order.map(&:id).max)
    create_orders(zines_to_order)
  end

end
