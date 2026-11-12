class Order < ApplicationRecord
  # Status flow from ERD §3. A key is the current status, the value lists the
  # statuses it can move to.
  TRANSITIONS = {
    "pending" => %w[paid cancelled],
    "paid" => %w[assembled cancelled],
    "assembled" => %w[shipped cancelled],
    "shipped" => %w[delivered],
    "delivered" => [],
    "cancelled" => []
  }.freeze

  PHONE_FORMAT = /\A\+?[\d\s\-()]{10,20}\z/

  # Raised when an order is placed from an empty cart.
  class EmptyCartError < StandardError
    def initialize(message = "Корзина пуста")
      super
    end
  end

  # Raised when a variant cannot cover the requested quantity. The whole
  # placement transaction is rolled back.
  class InsufficientStockError < StandardError
    attr_reader :variant

    def initialize(variant)
      @variant = variant
      super(build_message(variant))
    end

    private
      def build_message(variant)
        if variant.product.active?
          "Недостаточно товара на складе: #{variant.product.name} (#{variant.label}), доступно: #{variant.stock}"
        else
          "Товар недоступен: #{variant.product.name}"
        end
      end
  end

  # Raised when a status change is not allowed by TRANSITIONS.
  class InvalidTransitionError < StandardError
    def initialize(message = "Недопустимый переход статуса заказа")
      super
    end
  end

  belongs_to :user
  has_many :order_items, dependent: :destroy, inverse_of: :order

  enum :status, { pending: 0, paid: 1, assembled: 2, shipped: 3, delivered: 4, cancelled: 5 },
       default: :pending

  validates :full_name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, format: { with: PHONE_FORMAT }
  validates :address, presence: true
  validates :number, presence: true, uniqueness: true
  validates :subtotal, :delivery_price, :total,
            numericality: { greater_than_or_equal_to: 0 }
  validates :order_items, presence: true
  validate :total_must_equal_sum

  before_validation :assign_number, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :not_cancelled, -> { where.not(status: :cancelled) }
  scope :revenue, -> { not_cancelled.sum(:total) }

  # Places an order from the cart in a single transaction. Every variant is
  # locked by id (a fixed order, so concurrent checkouts cannot deadlock),
  # checked against the stock and decremented. Snapshots of the product name,
  # size, colour and price are stored on the order items. Any error rolls the
  # whole transaction back: stock, order and cart stay untouched.
  def self.place_from_cart!(cart, attributes)
    transaction do
      items = cart.cart_items.includes(variant: :product).order(:variant_id).to_a

      raise EmptyCartError if items.empty?

      order = cart.user.orders.build(attributes)

      items.each do |item|
        variant = item.variant.lock!
        raise InsufficientStockError.new(variant) unless variant.available?(item.quantity)

        variant.update!(stock: variant.stock - item.quantity)
        order.order_items.build(
          variant: variant,
          product_name: variant.product.name,
          size: variant.size,
          color: variant.color,
          unit_price: variant.product.price,
          quantity: item.quantity
        )
      end

      order.subtotal = order.order_items.sum(&:subtotal)
      order.delivery_price = Delivery.price_for(order.subtotal)
      order.total = order.subtotal + order.delivery_price
      order.save!
      cart.cart_items.delete_all

      order
    end
  end

  def items_count
    order_items.sum(:quantity)
  end

  def available_transitions
    TRANSITIONS.fetch(status, [])
  end

  def can_transition_to?(new_status)
    available_transitions.include?(new_status.to_s)
  end

  # Moves the order to the next status. Cancellation goes through cancel!,
  # which also returns the stock.
  def transition_to!(new_status)
    new_status = new_status.to_s

    raise InvalidTransitionError, "Неизвестный статус: #{new_status}" unless self.class.statuses.key?(new_status)

    return cancel! if new_status == "cancelled"

    with_lock do
      raise InvalidTransitionError, transition_error_message(new_status) unless can_transition_to?(new_status)

      update!(status: new_status)
    end
  end

  # Cancels the order and returns every item to its variant stock. The order
  # and the variants are locked, so the stock cannot be returned twice.
  def cancel!
    transaction do
      lock!
      raise InvalidTransitionError, transition_error_message("cancelled") unless can_transition_to?("cancelled")

      order_items.includes(:variant).order(:variant_id).each do |item|
        variant = item.variant.lock!
        variant.update!(stock: variant.stock + item.quantity)
      end

      update!(status: :cancelled)
    end
  end

  private
    def assign_number
      return if number.present?

      self.number = "ORD-#{Date.current.strftime('%Y%m%d')}-#{SecureRandom.hex(2).upcase}"
    end

    def total_must_equal_sum
      return if subtotal.nil? || delivery_price.nil? || total.nil?
      return if total == subtotal + delivery_price

      errors.add(:total, :not_equal_to_sum)
    end

    def transition_error_message(new_status)
      "Нельзя перевести заказ из статуса «#{status}» в «#{new_status}»"
    end
end
