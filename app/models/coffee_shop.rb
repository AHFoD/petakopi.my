class CoffeeShop < ApplicationRecord
  has_paper_trail on: [:update]

  serialize :urls, HashSerializer
  store_accessor :urls,
    :facebook,
    :google_embed,
    :google_map,
    :instagram,
    :twitter,
    :waze

  attr_accessor :logo_url

  enum(
    status: {
      unpublished: 0,
      published: 1,
      rejected: 2,
      duplicate: 3,
      reviewed: 4
    },
    _prefix: :status
  )

  belongs_to :submitter, class_name: "User", foreign_key: "submitter_user_id", optional: true
  has_many :coffee_shop_tags
  has_many :tags, through: :coffee_shop_tags

  has_one_attached :logo

  validates :slug, presence: true
  validates :slug, uniqueness: true
  validates :state, presence: true
  validates :district, presence: true
  validate :verify_district_in_state

  before_validation :assign_slug, on: :create
  before_validation :convert_google_embed
  after_save :process_logo

  accepts_nested_attributes_for :coffee_shop_tags

  def assign_slug
    return if name.blank?
    return if district.blank?

    slug = name.parameterize

    if CoffeeShop.where(slug: slug).any?
      slug = "#{slug}-#{district.parameterize}"
    end

    if CoffeeShop.where(slug: slug).any?
      slug = "#{slug}-#{SecureRandom.alphanumeric(5).downcase}"
    end

    self.slug = slug.downcase
  end

  def verify_district_in_state
    return if state.nil? || district.nil?

    Location.find_by(city: district).state == state
  end

  def convert_google_embed
    return if google_embed.blank?
    return unless google_embed.starts_with?("<iframe")

    self.google_embed =
      Nokogiri::HTML.parse(google_embed).xpath('//iframe').attr('src').value
  end

  def process_logo
    return unless logo.attached?
    return unless attachment_changes.dig("logo").present?
    # hack to ensure we only do it if filename is not based on calculated format
    return if logo.filename.to_s.match? /#{id}-[0-9]+/

    # Too costly, use vips-gem
    # ProcessLogoWorker.perform_in(2.minutes, id)
  end
end
