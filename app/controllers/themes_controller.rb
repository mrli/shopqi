#encoding: utf-8
class ThemesController < ApplicationController
  prepend_before_filter :authenticate_user!, except: [:index, :show, :download, :login, :filter]
  layout 'admin'
  layout 'theme', only: [:index, :show, :download]

  expose(:shop) { current_user.shop }
  expose(:theme) { shop.theme }
  expose(:settings_html) { theme.settings.transform }
  expose(:settings_json) { theme.settings.as_json.to_json }

  begin 'store'

    def index
    end

    def show
      theme = Theme.find_by_name_and_style(params[:name], params[:style])
      @theme_json = theme.attributes.to_json
      styles = Theme.find_all_by_name(params[:name])
      others = Theme.find_all_by_author(theme.author).take(4)
      @styles_json = styles.inject([]) do |result, theme|
        result << theme.attributes; result
      end.to_json
      @others_json = others.inject([]) do |result, theme|
        result << { theme: theme.attributes }; result
      end.to_json
    end

    def download # 确认切换主题
      access_token = client.web_server.get_access_token params[:code], redirect_uri: oauth_callback_url
      me = access_token.get('/api/me')
      #ap me
      render :text => access_token
    end

    def apply # 切换主题
    end

    def login # 未登录时提示用户登录或者注册(如果直接跳转至登录页面则对未注册用户不友好)
      redirect_to client.web_server.authorize_url(
        :redirect_uri => oauth_callback_url
      )
    end

    def authenticate # 跳转至登录页面oauth
      redirect_to "#{params[:shop]}/auth/login"
    end

    def filter # 查询主题
      session[:q] = request.query_string
      price = params[:price]
      color = params[:color]
      themes =  Theme.all.clone # 一定要复制
      themes.select! {|t| t.price == 0} if price == 'free'
      themes.reject! {|t| t.price == 0} if price == 'paid'
      themes.select! {|t| t.color == color} unless color.blank?
      themes_json = themes.inject([]) do |result, theme|
        result << { theme: theme.attributes }; result
      end.to_json
      render json: themes_json
    end

  end

  begin 'admin' # 后台管理

    def settings # 主题配置
    end

    def update # 更新主题配置
      preset = params[:theme][:save_preset][:existing]
      preset = params[:theme][:save_preset][:new] if preset.blank?
      preset = params[:theme][:load_preset] if preset.blank?
      theme.settings.save preset, params[:theme][:settings]
      render json: params[:theme][:settings]
    end

    def delete_preset # 删除预设
      theme.settings.destroy_preset params[:name]
      render nothing: true
    end

  end


  protected
  def client
    @client ||= OAuth2::Client.new(
      '4rvacrldtx5w5utihdp50i328',
      '5lvh1ml1ategg8v6udc1n99rd',
      site: 'http://lvh.me:4001'
    )
  end

  def oauth_callback_url
    'http://themes.lvh.me:4000/themes/Prettify/styles/default/download'
  end
end
