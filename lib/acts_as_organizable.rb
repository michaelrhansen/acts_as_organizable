# To find a person's available tags for the object we go through owned_tags, which pulls uniq items from join table

require "acts_as_organizable/version"
path = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << path unless $LOAD_PATH.include?(path)
require 'acts_as_organizable/tag'
require 'acts_as_organizable/tagging'
require 'acts_as_organizable/core_ext/string'

module ActsAsOrganizable
  class TagList < Array
    cattr_accessor :delimiter
    @@delimiter = ','
    
    def initialize(list)
      list = list.is_a?(Array) ? list : list.split(@@delimiter).collect(&:strip).reject(&:blank?)
      super
    end
    
    def to_s
      join(@@delimiter + " ")
    end
  end

  module ActiveRecordExtension
    def acts_as_organizable(*kinds)
      # Example: acts_as_organizable :tags, :languages
      class_inheritable_accessor :tag_kinds
      self.tag_kinds = kinds.map(&:to_s).map(&:singularize)
      self.tag_kinds << :tag if kinds.empty?

      include ActsAsOrganizable::TaggableMethods
    end
    
    def acts_as_tagger(opts={})
      class_eval do
        has_many :owned_tags, :through => :owned_taggings, :source => :tag, :class_name => "Tag", :uniq => true
        has_many :owned_taggings, opts.merge(:as => :owner, :dependent => :destroy, :include => :tag, :class_name => "Tagging")
      end
    end
  end

  module TaggableMethods
    def self.included(klass)
      klass.class_eval do
        include ActsAsOrganizable::TaggableMethods::InstanceMethods

        has_many :taggings, :as => :taggable, :dependent => :destroy
        has_many :tags, :through => :taggings
        before_save :cache_tags

        tag_kinds.each do |k|
          # Example: language gets passed in and becomes language_list
          define_method("#{k}_list") { get_tag_list(k) }
          # this is expexting language_list = "spanish, italian" 
          define_method("#{k}_list=") { |new_list| set_tag_list(k, new_list.clean_up_tags) }
        end
      end
    end

    module InstanceMethods
      def set_tag_list(kind, list)
        tag_list = TagList.new(list) # ["spanish", "italian"]
        # @language_list = ["spanish", "italian"]
        instance_variable_set(tag_list_name_for_kind(kind), tag_list)
      end

      def get_tag_list(kind)
        # set instance variable unless it exists
        set_tag_list(kind, tags.of_kind(kind).map(&:name)) if tag_list_instance_variable(kind).nil?
        tag_list_instance_variable(kind)
      end
      
      def save_with_tags(tag_owner = nil)
        if self.save # save the parent object first
          tag_kinds.each do |tag_kind|
            delete_unused_tags(tag_kind)
            create_taggings(tag_kind, tag_owner)
          end
        else
          return false
        end
      end

      protected
        def tag_list_name_for_kind(kind)
          "@#{kind}_list"
        end
        
        def tag_list_instance_variable(kind)
          instance_variable_get(tag_list_name_for_kind(kind))
        end
        
        def delete_unused_tags(tag_kind)
          # if the new list does not have the previous tag, kill the old tag associated to the object
          tags.of_kind(tag_kind).each { |t| tags.delete(t) unless get_tag_list(tag_kind).include?(t.name) }
        end
        
        def create_taggings(tag_kind, tag_owner)
          # get tags passed in, such as ["russian", "english"] from @language_list
          previous_tags = tags.of_kind(tag_kind).map(&:name)
          get_tag_list(tag_kind).each do |tag_name|
            tag = Tag.find_or_create_with_name_like_and_kind(tag_name, tag_kind) unless previous_tags.include?(tag_name)
            if tag_owner
              # save taggings to tag_owner passed in explicitly
              # NOTE: this includes visitors - they must be passed in explicitly 
              taggings.create!(:tag_id => tag.id, :owner => tag_owner)
            # look for user or owner of object to attach to tagging
            elsif user = (self.respond_to?(:owner) && self.try(:owner)) || (self.respond_to?(:user) && self.try(:user))
              taggings.create!(:tag_id => tag.id, :owner => user)
            else
              raise "No user asociated to tagging. Please specify one."
            end
          end
        end
        
        def cache_tags
          tag_kinds.each do |tag_kind|
            t = tag_kind.to_s
            if self.class.column_names.include?("cached_#{t}_list")
              list = get_tag_list(tag_kind).join(", ")
              self["cached_#{t}_list"] = list
            else
              logger.info("
                ************************************************************************************************
                You should consider adding cached_#{t}_list to your #{t} for performance benefits!
                ************************************************************************************************
                ")
            end
          end
        end
    end
  end
end

ActiveRecord::Base.send(:extend, ActsAsOrganizable::ActiveRecordExtension)
