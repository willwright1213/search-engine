require 'matrix'
class PopularsController < ApplicationController

  def index

    n = Page.count
    m = Matrix.build(n) { 0 }
    alpha = 0.1
    m_alpha = Matrix.build(n) { alpha/n.to_f }

    Link.all.each do |link|
      m[link.page_id - 1, link.link_to - 1] = 1
    end
    m.row_count().times do |i|
      ratio = m.row(i).dot(m.row(i))
      denominator = if ratio == 0
                      n.to_f 
                   else 
                     ratio.to_f
                   end
      n.times do |j|
        m[i,j] /= denominator
      end
    end
    m2 = ((1-alpha) * m)
    m2 = m2 + m_alpha

    stability_vector = Matrix.row_vector(Array.new(n) {|_i| 1.0/n})

    d1 = stability_vector.row(0).magnitude * m2.row(0).magnitude
    diff = 1
    until diff < 0.00001
      stability_vector = stability_vector * m2
      d2 = stability_vector.row(0).magnitude * m2.row(0).magnitude
      diff = (d1 - d2).abs
      d1 = d2
    end

    # retrieve top 25 most populars
    links = Link.select("link_to").group(:link_to).order('count(link_to) desc').limit(25).count
    p links
    @json = []

    print stability_vector.row(0)

    links.each do |link|
      page = Page.find(link[0])
      host = page.host
      @json.push({:score => stability_vector.row(0)[page.id - 1],:id => page.id, :page => URI.join(host.name, page.name).to_s})
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

  def query
    if params[:q].nil?
      return
    end


    scores = Hash.new
    n = Page.count
    document_vectors = Hash.new
    queries = params[:q].split
    queries_tally = queries.tally
    query_vector = Vector.zero(queries_tally.size)
    i = 0
    queries_tally.each do |term, count|
      word = Word.find_by(token: term)
      unless word.nil?
        indices = Index.where(word_id: word.id)
        idf = Math.log(n.to_f/indices.count)
        query_vector[i] = BigDecimal((Math.log(1 + count) * idf).to_s) 
        indices.each do |index|
          tf = index.frequency.to_f
          doc_rel = BigDecimal(Math.log(1 + tf).to_s) * BigDecimal(idf.to_s)
          if document_vectors.include?(index.page_id)
            document_vectors[index.page_id][i] = doc_rel 
          else
            v = Vector.zero(queries_tally.size)
            v[i] = doc_rel
            document_vectors[index.page_id] = v
          end
        end
      else
        query_vector[i] = 0
      end
      i += 1
    end
    document_vectors.each do |page_id, vector|
      scores[page_id] = BigDecimal(query_vector.inner_product(vector).to_s)/BigDecimal((query_vector.magnitude * vector.magnitude).to_s)
    end

    scores = scores.sort_by{|_k, v| -v }

    @sites = Array.new
    10.times {|i|
      data = Hash.new
      page = Page.find(scores[i][0])
      host = Host.find(page.host_id).name
      data[:website] = URI.join(host, Page.find(scores[i][0]).name).to_s
      data[:score] = scores[i][1]
      data[:title] = page.title
      @sites.push(data)
    }
  puts document_vectors
  end


  def ranks
    n = Page.count
    m = Matrix.build(n) { 0 }
    alpha = 0.6
    m_alpha = Matrix.build(n) { alpha/n.to_f }

    #Let's populate our rows
    Link.all.each do |link|
      m[link.page_id - 1, link.link_to - 1] = 1
    end
    m.row_count().times do |i|
      ratio = m.row(i).dot(m.row(i))
      denominator = if ratio == 0
                      n.to_f 
                   else 
                     ratio.to_f
                   end
      n.times do |j|
        m[i,j] /= denominator
      end
    end
    m2 = ((1-alpha) * m)
    m2 = m2 + m_alpha

    stability_vector = Matrix.row_vector(Array.new(n) {1/n})
    stability_vector[0, 0] = 1

    d1 = stability_vector.row(0).magnitude * m2.row(0).magnitude
    diff = 1
    until diff <= 0.00001
      stability_vector = stability_vector * m2
      d2 = stability_vector.row(0).magnitude * m2.row(0).magnitude
      diff = (d1 - d2).abs
      d1 = d2
    end

    top10 = []

    ranked_array = stability_vector.row(0).to_a.sort
    p ranked_array

  end
end
