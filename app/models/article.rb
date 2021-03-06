#encoding: UTF-8
class Article < ActiveRecord::Base

  #软删除
  acts_as_paranoid

  #标签插件
  acts_as_taggable
  
  #栏目
  belongs_to :channel
  #用户
  belongs_to :member
  #文章内容
  has_one :article_content,   :dependent => :destroy
  #图片附件
  has_many :attached_pictures,    :dependent => :destroy, :as  => "item"


  #注册模板字段
  mango_liquid %w(thumb methods)



  #倒序查询
  scope :ct_desc , order("created_at DESC")
  #正序查询
  scope :ct_asc , order("created_at ASC")

  #文章是否审核
  scope :is_status , where(:status => 1)

  #--------------------验证---------------------
  #产品名不能为空
  validates :title,   :presence => {:message => "文章标题不能为空"}
  validates :channel_id,   :presence => {:message => "栏目不能为空"}
  #产品名不能重复
  # validates :title,   :uniqueness => {:message =>  "文章标题不能重复"}


  #如果文章导读为空就取内容的第一段当导读
  after_save :set_description



  RECOMMENT = [["不推荐",0],["1级",1],["2级",2],["3级",3]]
  STATUS = [["正常",1],["未审核",0]]


  #图片
  
  has_attached_file :thumb, :styles => { :s1 => "240x179#", :s2 => "421x351#", :s3 => "104x84#"},
    :url => "/upload/thumbs/articles/:id_partition/:style/:filename",
    :default_url   => "/assets/nopic.gif"
  #以K计算的限制
  #  validates_attachment_size :thumb, :less_than => 10.kilobytes
  #限制图片上传最大为2M
  validates_attachment_size :thumb, :less_than => 2.megabytes
  validates_attachment_content_type :thumb, :content_type => [ 'image/gif', 'image/png', 'image/x-png', 'image/jpeg', 'image/pjpeg', 'image/jpg']

  # 返回推荐等级
  #
  # 作者:  佟立家
  # 最后更新时间: 2012-03-08c
  #
  # ==== 参数
  #
  # ==== 返回
  #   1级    2级    3级 不推荐

  def get_recomment_type
    RECOMMENT.find_all{|recomment| recomment[1] == self.recomment}[0][0]
  end 

  # 模板标签（cms_Article）操作数据库方法
  #
  # 作者: 朱文博
  # 最后更新时间: 2012-3-9
  #
  # ==== 参数
  # * <tt>attributes</tt> - 注入参数,对应模板标签参数的hash
  # * <tt>options</tt> - 配置参数
  #
  # ==== 模板示例
  #   {% cms_Article vo in channel:1 limit:5 recomment:all image:true order:"created_at ASC" tags:"" %}
  #     {{vo.title}}
  #   {% endcms_Article%}
  #
  # ==== 返回
  #   集合<Article>
  #
  def self.cms_liquid_each(attributes, options)
    #设置url
    options[:url] = "/articles/${id}"
     if  attributes["article_tag"] &&  article =  Article.find_by_id(attributes["article_tag"].to_i)
        temp =  Article.tagged_with(article.tag_list, :any => true) 
     else
    #主体
        temp = self.order(attributes["order"] || "updated_at DESC")
     end
   
    temp = temp.limit(attributes["limit"] || 5)
    temp = temp.offset(attributes["offset"]) if attributes["offset"]
    temp = temp.select(attributes["column"]) if attributes["column"]    
    if attributes["channel_id"]
      channel_id = attributes["channel_id"]
      if channel_id.class == Fixnum
        if attributes["level"]
          next_node = Channel.next_node(Channel.find(channel_id))
          if next_node.size > 0
            channel_id = next_node
          end
        end
        temp = temp.where(:channel_id => channel_id)
      elsif channel_id.class == String #调用多个栏目
        temp = temp.where(:channel_id => channel_id.split(/\s+|,/))
      end
    end
    recomment = attributes["recomment"]
    if recomment&&recomment == "all"
      temp = temp.where(["recomment > 0"])
    elsif recomment
      temp = temp.where(:recomment => recomment)
    end
    temp = temp.where("thumb_file_name IS NOT NULL") if attributes["image"]
    #审核状态
    temp = temp.where("article_status = 1")
    temp
  end
 

   
  
  # 返回文章状态
  #
  # 作者:  佟立家
  # 最后更新时间: 2012-03-15
  #
  # ==== 参数
  #
  # ==== 返回
  #    通过，未审核

  def get_article_status
    self.article_status.to_i == 0 ? "未审核" : "正常"
  end

  # 标签搜索扩展
  #
  # 作者: 佟立家
  # 最后更新时间: 2012-03-29
  #
  # ==== 参数
  # * <tt>tag</tt> - 标签
  # * <tt>args</tt> - 分页插件参数
  #
  # ==== 示例
  #   Article.paged_find_tagged_with params[:tag], :page => params[:page] || 1, :per_page => 10
  #
  # ==== 返回
  # Array[Article]
  def self.paged_find_tagged_with(tags, args = {})
    if tags.blank?
      paginate args
    else
      options = find_options_for_find_tagged_with(tags, :match_all => true)
      options.merge!(args)
      paginate(options.merge(:count => { :select => options[:select].gsub('*', 'id') }, :conditions => ["articles.article_status = ?", ARTICLE_STATUS_READY]))
    end
  end

 

  #  提取内容字段的第二段信息， 如果没有的话，就提第一段，如果还没有的话， 就返回空
  #
  # 作者: 佟立家
  # 最后更新时间: 2012-03-29
  #
  # ==== 示例
  #    self.first_p_content
  #
  # ==== 返回
  #  
  def first_p_content
    require 'hpricot'
    Hpricot(self.article_content.content).search("//p[1]").text
  end



  #  根据where条件返回文章列表
  #
  # 作者: 佟立家
  # 最后更新时间: 2012-04-28
  #
  #参数
  #<tt>article    </tt>   当然过滤的文章对象
  #<tt>channel    </tt>   当前栏目
  #<tt>start_time    </tt>   开始时间
  #<tt>end_time    </tt>     结束时间
  #<tt>currn_page    </tt>   当前页
  #<tt>per_page=20    </tt>   默认分页20条数据
  # ==== 示例
  #    self.article_where(article,channel,start_time,end_time,currn_page,per_page=20)
  #
  # ==== 返回
  #
  def self.article_where(article,channel,start_time,end_time,currn_page = 1,per_page=20)
    articles = channel.articles if channel
    if article.present?
      articles = articles.where("title like ?", "%#{article.title}%")   if article.title.present?
      articles = articles.where("recomment = ?", article.recomment )   if article.recomment.present? && article.recomment.to_i != 0
    end
    articles = articles.where("TO_DAYS(created_at) >= TO_DAYS(?) ", start_time)  if start_time.present?
    articles = articles.where("TO_DAYS(created_at) <= TO_DAYS(?) ", end_time)    if end_time.present?
    articles = articles.order("created_at DESC")
    articles = articles.page(currn_page).per(per_page)
  end




  private
  #如果描述为空就取内容第一段赋值给它
  #
  # 作者: 佟立家
  # 最后更新时间: 2012-03-29
  #
  # ==== 示例
  # 
  # ==== 返回
  #  
  def set_description
    unless self.description.present?
      if self.article_content
        if self.article_content.content.present?
          description = self.first_p_content.truncate(60).strip
          description.blank? and return
        else
          return
        end
        self.update_attributes(:description => description)
      end
    end
  end
end
