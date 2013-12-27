class Blog < ActiveRecord::Base
  include TruncateHtmlHelper
  extend Enumerize
  enumerize :status, :in => {:draft => 0, :publish => 1}, :predicates => true, :scope => true

  acts_as_ordered_taggable

  validates :title, :length => {:in => 3..100}
  validates :content, :length => {:in => 10..100000}
  validates :slug, :uniqueness => true

  before_validation :clean_slug
  before_save :fill_slug
  before_save :fill_html_content
  after_save :update_blog_count

  belongs_to :category
  #has_many :attaches, :as=>:parent, :dependent => :destroy

  def publish!
    self.status = :publish
    self.save
  end

  # 将slug中的非法字符过滤掉
  def clean_slug
    self.slug = self.slug.gsub(/[^a-zA-Z\-0-9]/, '-').downcase if self.slug.present?
  end

  # 如果没有slug则用时间戳代替
  def fill_slug
    self.slug = Time.now.to_i.to_s if self.slug.blank?
  end

  # 将 Markdown 转为 HTML 保存，并保存摘要
  def fill_html_content
    self.html_content = Klog::Markdown.render(self.content)
    self.html_content_summary = truncate_html(self.html_content, :length => 250, :omission => '', :break_token => '<!-- truncate -->')
  end

  # 更新分类的 blog_count
  def update_blog_count
    # 如果状态变动或者分类变动，重算当前分类
    category.update_blog_count if status_changed? or category_id_changed?
    # 如果分类变动，重算之前的分类
    Category.find(category_id_was).update_blog_count if category_id_changed?
  end
end