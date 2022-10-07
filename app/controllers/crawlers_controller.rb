class CrawlersController < ApplicationController
  protect_from_forgery with: :null_session
  def crawl

    crawlers = CoolCrawler::CrawlerPool.new(params[:root], 10, 0.01)
    website = crawlers.site

    @host = Host.find_or_create_by(name: website)

    callback = Proc.new { |page, links|
      @page = Page.find_or_create_by(host_id: @host.id, name: page)
      links.each do |link|
        @in_page = Page.find_or_create_by(host_id: @host.id, name: link)
        @in_page.links.create(link_to: @page.id) 
      end
    }

    crawlers.set_callback(callback)
    crawlers.run

    render body: "crawling completed"

  end

end
