require 'mongoid/tree/traversal'

module Mongoid # :nodoc:
  ##
  # = Mongoid::Tree
  #
  # This module extends any Mongoid document with tree functionality. 
  # 
  # == Usage
  #
  # Simply include the module in any Mongoid document:
  # 
  #   class Node
  #     include Mongoid::Document
  #     include Mongoid::Tree
  #   end
  #
  # === Using the tree structure 
  #
  # Each document references many children. You can access them using the <tt>#children</tt> method.
  #
  #   node = Node.create
  #   node.children.create
  #   node.children.count # => 1
  #
  # Every document references one parent (unless it's a root document).
  #
  #   node = Node.create
  #   node.parent # => nil
  #   node.children.create
  #   node.children.first.parent # => node
  # 
  module Tree
    extend ActiveSupport::Concern

    include Traversal
  
    included do
      references_many :children, :class_name => self.name, :foreign_key => :parent_id, :inverse_of => :parent
      referenced_in :parent, :class_name => self.name, :inverse_of => :children
    
      field :parent_ids, :type => Array, :default => []
    
      set_callback :validation, :before, :rearrange
      set_callback :save, :after, :rearrange_children, :if => :rearrange_children?
    end
    
    ##
    # :method: children
    # Returns a list of the document's children. It's a <tt>references_many</tt> association.
    # (Generated by Mongoid)
    
    ##
    # :method: parent
    # Returns the document's parent (unless it's a root document).  It's a <tt>referenced_in</tt> association.
    # (Generated by Mongoid)
    
    ##
    # :method: parent_ids
    # Returns a list of the document's parent_ids, starting with the root node.
    # (Generated by Mongoid)
    
    ##
    # Is this document a root node (has no parent)? 
    def root?
      parent_id.nil?
    end
    
    ##
    # Is this document a leaf node (has no children)?
    def leaf?
      children.empty?
    end
    
    ##
    # Returns this document's root node
    def root
      self.class.find(parent_ids.first)
    end
    
    ##
    # Returns this document's ancestors
    def ancestors
      self.class.find(:conditions => { :_id.in => parent_ids })
    end
    
    ##
    # Returns this document's ancestors and itself
    def ancestors_and_self
      ancestors + [self]
    end
    
    ##
    # Is this document an ancestor of the other document?
    def ancestor_of?(other)
      other.parent_ids.include?(self.id)
    end 
    
    ##
    # Returns this document's descendants
    def descendants
      self.class.find(:conditions => { :parent_ids => self.id })
    end
    
    ##
    # Returns this document's descendants and itself
    def descendants_and_self
      [self] + descendants
    end
    
    ##
    # Is this document a descendant of the other document?
    def descendant_of?(other)
      self.parent_ids.include?(other.id)
    end
    
    ##
    # Returns this document's siblings
    def siblings
      siblings_and_self - [self]
    end
    
    ## 
    # Returns this document's siblings and itself
    def siblings_and_self
      self.class.find(:conditions => { :parent_id => self.parent_id })
    end
    
    ##
    # Forces rearranging of all children after next save
    def rearrange_children!
      @rearrange_children = true
    end
  
    ##
    # Will the children be rearranged after next save?
    def rearrange_children?
      !!@rearrange_children
    end
  
    private
  
    def rearrange
      if self.parent_id
        self.parent_ids = self.class.find(self.parent_id).parent_ids + [self.parent_id]
      end
    
      rearrange_children! if self.parent_ids_changed?
      return true
    end
  
    def rearrange_children
      @rearrange_children = false
      self.children.find(:all).each { |c| c.save }
    end
  end
end