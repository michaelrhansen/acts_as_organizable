class Tag < ActiveRecord::Base
  class << self
    def find_or_create_with_name_like_and_kind(name, kind)
      with_name_like_and_kind(name, kind).first || create!(:name => name, :kind => kind)
    end
  end

  has_many :taggings, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :kind

  scope :with_name_like_and_kind, lambda { |name, kind| { :conditions => ["name like ? AND kind = ?", name, kind] } }
  scope :of_kind, lambda { |kind| { :conditions => {:kind => kind} } }
end