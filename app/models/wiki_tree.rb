class WikiTree < ActiveRecord::Base
  has_many :pages, :class_name => "WikiPage"
  has_many :roots, :class_name => "WikiPage", :conditions => "is_root"
end
