class CrawlersController < ApplicationController
  protect_from_forgery with: :null_session
  def crawl

    crawlers = CoolCrawler::CrawlerPool.new(params[:root], 10, 0.1)
    website = crawlers.site

    @host = Host.create_or_find_by(name: website)

    callback = Proc.new { |page, links|
      @path = Path.create_or_find_by(host_id: @host.id, name: page)
      links.each do |link|
        Link.create_or_find_by(path_id: @path.id, name: link)
      end
    }

    crawlers.set_callback(callback)
    crawlers.run
    p "Crawling complete"
  end
end
