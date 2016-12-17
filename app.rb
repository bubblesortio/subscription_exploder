require "shopify_api"

zines = [
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

variant_count = {1218878945=>(6..11), 1195972389=>(0..5), 1342622465=>(0..11)}
variant_zines = variant_count.map{|id, range| [id, zines[range]] }.to_h

module ShopifyAPI
  class Base
    RETRY_AFTER = 60

    def self.find_all(params = {}, &block)
      params[:limit] ||= 50
      params[:page] = 1
      retried = false

      begin
        until find(:all, :params => params).each { |value| block.call(value) }.length < params[:limit]
          params[:page] += 1
          retried = false
        end
      rescue ActiveResource::ConnectionError, ActiveResource::ServerError,
        ActiveResource::ClientError => ex
        unless retried
          sleep(((ex.respond_to?(:response) && ex.response['Retry-After']) || RETRY_AFTER).to_i)
          retried = true
          retry
        else
          raise ex
        end
      end
    end
  end
end

last_order_id = 1
# last_order_id get from database

zines_to_order = []
Order.find_all(since_id: last_order_id).each do |sub|
  sub.line_items.each do |li|
    next unless variant_zines.has_key?(li.variant_id)
    names = variant_zines[li.variant_id]
    zines_to_order.push(
      email: sub.email,
      quantity: li.quantity,
      zines: names,
      shipping_address: sub.shipping_address.attributes,
      note: sub.note,
      number: sub.name
    )
  end
  last_order_id = sub.id
end; nil

# last_order_id save to database

zines_to_order.each do |to_order|
  to_order[:zines].each do |title|
    to_order = zines_to_order.first
    title = to_order[:zines].first
    Order.create(
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

