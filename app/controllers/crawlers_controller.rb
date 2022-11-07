require 'nokogiri'
require 'rwordnet'
require 'matrix'
class CrawlersController < ApplicationController
  protect_from_forgery with: :null_session
  def crawl

    return
    stop_words = Set.new

    #load stopwords list
    File.readlines('lib/assets/stopwords.txt', chomp: true).each do |line|
      stop_words.add(line)
    end

    crawlers = CoolCrawler::CrawlerPool.new(params[:root], 10, 0.01, params[:lim].to_i)
    website = crawlers.site

    link_map = {}
    tags = unless params[:tags].nil?
             params[:tags].split
           else
             ["//p", "//h1", "//h2", "//h3", "//title", "//meta[@name]"]
           end
    tag_lim = params[:tag_lim].to_i

    @host = Host.find_or_create_by(name: website)
    callback = Proc.new { |page, links, body|
      doc = Nokogiri::HTML(body)
      @page = Page.find_or_create_by(host_id: @host.id, name: page)
      @page.title = doc.title
      @page.save
      link_map[@page.id] = []
      links.each do |link|
        in_page = Page.find_by(host_id: @host.id, name: link)
        unless in_page.nil?
          @page.links.create(link_to: in_page.id)
        else
          link_map[@page.id].push(link)
        end
      end

      word_bank = {}

      tags.each do |tag|
        tag_count = 0
        doc.css(tag).each do |x|
          break if tag_count == tag_lim
         
          words = []
          if tag == "meta[@name]"
            next unless x['name'] == 'keywords' || x['name'] == 'description'
            words = x['content'].split
          else
            words = x.content.split.slice(0,35)
          end

          words.each_index do |i|
            words[i] = /^[a-zA-Z]+/.match(words[i])
            next if words[i].nil?
            
            lemm = WordNet::Synset.morphy_all(words[i][0].downcase)
            if lemm.size > 0
              words[i] = lemm[0]
            else
              words[i] = words[i][0].downcase
            end
            if word_bank.include?(words[i])
              word_bank[words[i]] += 1
            else
              word_bank[words[i]] = 1
            end
          end
          tag_count += 1
        end
      end
      word_bank.each do |word, count|
        next if stop_words.include?(word) || word.size < 3

        @word = Word.find_or_create_by(token: word)
        index = Index.find_or_create_by(word_id: @word.id, page_id: @page.id)
        index.frequency = count
        index.save
      end
    }

    crawlers.set_callback(callback)
    crawlers.run

    link_map.each do |page,links|
      links.each do |link|
        @in_page = Page.find_by(host_id: @host.id, name: link)
        unless @in_page.nil?
          Link.create(page_id: page, link_to: @in_page.id)
        end
      end
    end

    render body: "crawling completed"

  end

  def pagerank
    host = Host.find(params[:id])
    n = host.pages.count
    alpha = 0.1
    m = Matrix.zero(n)
    m_alpha = Matrix.build(n) { alpha/n.to_f }
    offset = host.pages.minimum("id")
    host.pages.each do |page|
      links = Link.where(page_id: page.id)
      if links.nil?
        n.times do |i|
          m[link.page_id - offset, i] = 1.0/n
        end
      else
        links.each do |link|
          m[link.page_id - offset, link.link_to - offset] = 1.0/links.size
        end
      end
    end
    m2 = ((1-alpha) * m)
    m2 = m2 + m_alpha

    stability_vector = Matrix.row_vector(Array.new(n) {|_i| 1.0/n})

    d1 = stability_vector.row(0).magnitude * m2.row(0).magnitude
    diff = 1
    until diff < 0.0001
      stability_vector = stability_vector * m2
      d2 = stability_vector.row(0).magnitude * m2.row(0).magnitude
      diff = (d1 - d2).abs
      d1 = d2
    end

    #update page rank score
    n.times do |i|
      Page.find(i + offset).update(page_rank: stability_vector[0,i])
    end

  end

end
