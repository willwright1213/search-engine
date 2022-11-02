require 'nokogiri'
require 'rwordnet'
require 'matrix'
class CrawlersController < ApplicationController
  protect_from_forgery with: :null_session
  def crawl

    stop_words = Set.new

    #load stopwords list
    File.readlines('lib/assets/stopwords.txt', chomp: true).each do |line|
      stop_words.add(line)
    end

    crawlers = CoolCrawler::CrawlerPool.new(params[:root], 10, 0.01, 1000)
    website = crawlers.site

    link_map = {}

    @host = Host.find_or_create_by(name: website)
    callback = Proc.new { |page, links, body|
      doc = Nokogiri::HTML(body)
      @page = Page.find_or_create_by(host_id: @host.id, name: page)
      @page.title = doc.title
      @page.save
      link_map[@page.id] = links
      doc.xpath("//p").each do |p|
        words = p.content.split
        words.each_index do |i|
          word = /[a-zA-Z]+'?[a-zA-Z]*/.match(words[i])
          unless word.nil?
            nouns = WordNet::Synset.morphy(word[0], 'noun')
            verbs = WordNet::Synset.morphy(word[0], 'verb')
            if nouns.size > 0
              words[i] = nouns[0]
            elsif verbs.size > 0
              words[i] = verbs[0]
            else
              words[i] = nil
            end
          else
            words[i] = nil
          end
        end
        words_tally = words.tally
        words_tally.each do |word, count|
          next if word.nil?
          next if stop_words.include?(word.downcase) || word.size < 2

          @word = Word.find_or_create_by(token: word.downcase)
          Index.find_or_create_by(word_id: @word.id, page_id: @page.id, frequency: count)
        end
      end
    }

    crawlers.set_callback(callback)
    crawlers.run

    link_map.each do |page,links|
      @page = Page.find(page)
      links.each do |link|
        @in_page = Page.find_by(host_id: @host.id, name: link)
        unless @in_page.nil?
          @in_page.links.create(link_to: @page.id)
        end
      end
    end

    render body: "crawling completed"

  end

  def pagerank
    host = Host.find(params[:id])
    n = host.pages.count
    puts n
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
    until diff < 0.000001
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
