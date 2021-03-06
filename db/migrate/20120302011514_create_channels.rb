#encoding: UTF-8
class CreateChannels < ActiveRecord::Migration
  def change
    create_table :channels, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      
      #-------------栏目基本信息------------------------
      t.column :name,         :string, :limit => 20, :null => true    #栏目名称
      t.column :title,        :string, :limit => 50                   #栏目标题
      t.column :keyword,      :string, :limit => 100                  #关键词
      t.column :description,  :string, :limit => 500                  #栏目描述
      t.column :path_customize,:string, :limit => 30, :null => true   #ID自定义
      t.column :single_page,  :boolean,:default => false              #是否为单页，默认为否
      t.column :final_page,   :boolean,:default => false              #是否为最终页，默认为否
      
      t.column :show_nav,     :boolean, :default => true              #导航是否显示 默认为显示
      t.column :channel_type, :integer, :default => 0                 #类型包括：原创内容|跳转| 默认:原创内容
      t.column :info_model_id,:integer                                #类型为原创内容时显示此项
      t.column :return_url,   :string, :limit => 300                  #设置跳转到其他链接上
      t.column :template_index,:string, :default => ""            #栏目模板
      t.column :template_list, :string, :default => ""             #列表模板
      t.column :template_detail,:string , :default => ""            #内容模板

      #-------------栏目分类------------------------
      t.column :parent_id,:integer                                    #父类ID
      t.column :lft,:integer                                          #左子树ID
      t.column :rgt,:integer                                          #右子树ID

      #-------------栏目图片------------------------
      t.column :thumb_file_name,            :string                   #文件名称
      t.column :thumb_content_type,         :string                   #文件类型
      t.column :thumb_file_size,            :integer                  #文件大小
      t.column :thumb_updated_at,           :datetime                 #文件更新时间

      #-------------栏目软删除------------------------
      t.column :deleted_at,     :datetime                             #软删除字段(非空为软删除数据)

      #-------------栏目排序------------------------
      t.column :position,       :integer                              #排序字段

      t.timestamps
    end
    #栏目初始化
    puts "栏目数据导入完成..." if channel = Channel.create(:name => "根节点", :path_customize => "root", :show_nav => false)
    # 添加用户中心
    puts "用户中心导入完成..." if Channel.create(:name => "用户中心", :path_customize => "user_center", :show_nav => false, :channel_type => Channel::CHANNEL_TYPE[:original], :info_model_id => 4, :parent_id => channel.id )
    puts "产品栏目导入完成..." if Channel.create(:name => "产品栏目", :path_customize => "products", :show_nav => false, :channel_type => Channel::CHANNEL_TYPE[:original], :info_model_id => 5, :parent_id => channel.id )
    puts "订单导入完成..." if Channel.create(:name => "订单管理", :path_customize => "order_manager", :show_nav => false, :channel_type => Channel::CHANNEL_TYPE[:original], :template_id_detail => 8 , :info_model_id => 3, :parent_id => channel.id )
    
  end

end
