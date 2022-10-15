require 'matrix'
require 'bigdecimal/util'
Float::DIG = 10
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

  def query
    scores = Hash.new
    n = Page.count
    frequency_sum = Index.group(:page_id).sum('frequency')
    document_vectors = Hash.new
    queries = params[:q].split
    query_vector = Vector.zero(queries.size)
    queries.each_index do |i|
      word = Word.find_by(token: queries[i])
      unless word.nil?
        indices = Index.where(word_id: word.id)
        idf = Math.log10(n.to_f/indices.count.to_f).to_d
        query_vector[i] = idf
        indices.each do |index|
          tf = index.frequency
          wtd = Math.log10(1 + tf) * idf
          if document_vectors.include?(index.page_id)
            document_vectors[index.page_id][i] = wtd
            scores[index.page_id] += (wtd * query_vector[i]).to_d
          else
            v = Vector.zero(queries.size)
            v[i] = wtd
            document_vectors[index.page_id] = v
            scores[index.page_id] = (wtd * query_vector[i]).to_d
          end
        end
      else
        query_vector[i] = 0
      end
    end
    p scores[1]
    p scores[6]
    p scores[3].to_d
    document_vectors.each do |page_id, vector|
      scores[page_id] = (scores[page_id].to_d/vector.magnitude.to_d).to_d
    end
    scores = scores.sort_by{|_k, v| -v }
    10.times {|i| p scores[i]}
    p document_vectors[1].magnitude
    p document_vectors[6].magnitude
    p document_vectors[3].magnitude
  end

end
