require 'matrix'
require 'rwordnet'
class SearchesController < ApplicationController

  def index

    @results = []
    scores = {}

    return if params[:website] != 'fruits' and params[:website] != 'personal'

    host = if params[:website] == 'fruits'
             Host.find(1)
           elsif params[:website] == 'personal'
             Host.find(2)
           end

    return if host.nil?

    limit = unless params[:limit].nil?
              [50, params[:limit].to_i.abs].min
            else
              10
            end

    boost = if params[:boost] == 'true'
              true
            else 
              false 
            end
    
    unless params[:q].nil?
      words = params[:q].split.collect { |q|
        nouns = WordNet::Synset.morphy(q, 'noun')
        verbs = WordNet::Synset.morphy(q, 'verb')
        if nouns.size > 0
          nouns[0]
        elsif verbs.size > 0
          verbs[0]
        end
      }
      limit.times do |i|
        data = Hash.new
        page = host.pages[i]
        host_name = host.name
        data[:id] = page.id
        data[:url] = URI.join(host_name, page.name).to_s
        data[:score] = 0
        data[:pagerank] = page.page_rank
        data[:title] = page.title
        data[:name] = "William Wright"
        @results.push(data)
      end
    else
      words = []
    end

    n = host.pages.count
    scores = {}

    if boost
      host.pages.each do |p|
        scores[p.id] = p.page_rank
      end
    end

    document_vectors = {}
    words_tally = words.tally
    query_vector = Vector.zero(words_tally.size)
    i = 0

    ### This block is going through each word of our query and
    ### populates the query and document vectors with their weighted scheme
    index_table = Index.joins(
      "
      INNER JOIN pages ON indices.page_id = pages.id
      AND pages.host_id=#{host.id}
      "
    )

    total_words = index_table.group('page_id').sum('frequency')

    words_tally.each do |token, count|
      word = Word.find_by(token: token)
      next if word.nil?

      indices = index_table.where(word_id: word.id)
      df = indices.count
      
      idf = unless df == 0
              BigDecimal(Math.log(Rational(n,df)).to_s)
            else
              0
            end
      query_vector[i] = Math.log(1 + count) * idf

      indices.each do |index|
        tf =  Math.log(1+index.frequency) #Rational(index.frequency,total_words[index.page_id])
        idf = BigDecimal((Math.log(Rational(n, df))).to_s)
        doc_rel = (tf * idf)
        if document_vectors.include?(index.page_id)
          document_vectors[index.page_id][i] = doc_rel
        else
          v = Vector.zero(words_tally.size)
          v[i] = doc_rel
          document_vectors[index.page_id] = v
        end
      end
      i += 1
    end


    ### Calculates the score

    document_vectors.each do |page_id, vector|
      unless scores[page_id].nil?
        scores[page_id] *= vector.dot(query_vector)/(vector.norm * query_vector.norm)
      else
        scores[page_id] = BigDecimal(vector.dot(query_vector).to_s)/(BigDecimal(vector.norm.to_s) * BigDecimal(query_vector.norm.to_s))
      end
    end


    sorted_scores = scores.sort_by{|_k, v| -v}

    p "starting top 10"

    limit.times do |i|
      break if i >= sorted_scores.size

      data = Hash.new
      page = Page.find(sorted_scores[i][0])
      host_name = host.name
      data[:id] = page.id
      data[:url] = URI.join(host_name, page.name).to_s
      data[:score] = sorted_scores[i][1]
      data[:title] = page.title
      data[:pagerank] = page.page_rank
      data[:name] = "William Wright"

      @results[i] = data
    end

    respond_to do |format|
      format.html
      format.json {
        render json: @results
      }
    end

  end

  def data
    @page = Page.find(params[:id])
    @host = @page.host
    @incoming_links = Page.joins(
      "INNER JOIN links on pages.id = links.page_id AND links.link_to = #{@page.id}"
    ).select("pages.*")

    @outgoing_links = Page.joins(
      "INNER JOIN links on pages.id = links.link_to AND links.page_id = #{@page.id}"
    ).select("pages.*")

    @words = Index.joins(
      "INNER JOIN words on indices.word_id = words.id AND indices.page_id = #{@page.id}"
    ).select("words.token, indices.frequency").reorder("frequency desc")


  end



end
