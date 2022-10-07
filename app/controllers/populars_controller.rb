class PopularsController < ApplicationController

  def index
    # retrieve top 10 most populars
    links = Link.select("link_to").group(:link_to).order('count(link_to) desc').limit(10).count

    @json = []

    links.each do |link|
      page = Page.find(link[0])
      host = page.host
      @json.push({:id => page.id, :page => URI.join(host.name, page.name).to_s, :count => link[1]})
    end
    render json: @json
  end

  def show
    links = Link.select(:page_id).where(link_to: params['id'].to_i)

    @pages = []

    links.each do |link|
      page = Page.find(link.page_id)
      host = page.host
      @pages.push(URI.join(host.name, page.name).to_s)
    end
    page = Page.find(params[:id])
    host = page.host
    render json: {:ingoing => URI.join(host.name, page.name).to_s, :pages => @pages}
  end

end
