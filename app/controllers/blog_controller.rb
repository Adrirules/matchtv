class BlogController < ApplicationController
  BLOG_PATH = Rails.root.join('app', 'content', 'blog')

  PER_PAGE = 10

  def index
    all = all_articles
    @total_pages   = [(all.length.to_f / PER_PAGE).ceil, 1].max
    @current_page  = [[params[:page].to_i, 1].max, @total_pages].min
    @articles      = all.slice((@current_page - 1) * PER_PAGE, PER_PAGE) || []

    @page_title = @current_page > 1 \
      ? "Blog football — Page #{@current_page} | Coup d'Envoi TV" \
      : "Blog football — Guides et analyses | Coup d'Envoi TV"
    @page_desc  = "Guides pratiques, comparatifs d'abonnements et analyses football rédigés par Adrien pour ne rater aucun match en 2026."
    expires_in 1.hour, private: true
  end

  def auteur
    @articles = all_articles
    @page_title = "Adrien - Auteur football | Coup d'Envoi TV"
    @page_desc  = "Adrien, passionné de foot et fondateur de Coup d'Envoi TV. Guides pratiques, analyses, programmes TV et droits diffusion du football français et européen."
    expires_in 1.hour, private: true
  end

  def show
    @article = load_article(params[:slug])
    render "errors/not_found", status: :not_found and return unless @article
    @page_title  = @article[:title]
    @page_desc   = @article[:meta_description]
    @article_html, @toc = render_markdown_with_toc(@article[:body])

    @derby_matches = []
    if @article[:derby_pairs].present?
      @derby_matches = @article[:derby_pairs].filter_map do |pair|
        team_a, team_b = pair
        Match.where(
          "(home_team ILIKE :a AND away_team ILIKE :b) OR (home_team ILIKE :b AND away_team ILIKE :a)",
          a: "%#{team_a}%", b: "%#{team_b}%"
        ).where("start_time >= ?", Time.current - 3.hours)
         .order(:start_time)
         .first
      end
    end

    @match_groups = []
    if @article[:match_groups].present?
      @match_groups = @article[:match_groups].filter_map do |group_name, pairs|
        matches = (pairs || []).filter_map do |pair|
          team_a, team_b = pair
          Match.where(
            "(home_team ILIKE :a AND away_team ILIKE :b) OR (home_team ILIKE :b AND away_team ILIKE :a)",
            a: "%#{team_a}%", b: "%#{team_b}%"
          ).where("start_time >= ?", Time.current - 3.hours)
           .order(:start_time)
           .first
        end
        matches.any? ? { name: group_name, matches: matches } : nil
      end
    end

    expires_in 1.hour, private: true
  end

  private

  def all_articles
    Dir.glob(BLOG_PATH.join('*.md')).filter_map { |f| parse_file(f) }
       .select { |a| a[:published_at] && a[:published_at] <= Date.today }
       .sort_by { |a| a[:published_at] }.reverse
  end

  def load_article(slug)
    file = BLOG_PATH.join("#{slug}.md")
    return nil unless File.exist?(file)
    article = parse_file(file, with_body: true)
    return nil if article && article[:published_at] && article[:published_at] > Date.today
    article
  end

  def parse_file(path, with_body: false)
    raw = File.read(path)
    return nil unless raw.start_with?('---')
    parts = raw.split('---', 3)
    return nil if parts.length < 3
    meta = YAML.safe_load(parts[1], permitted_classes: [Date]) rescue {}
    body_text = parts[2].strip
    word_count = body_text.gsub(/[#*`\[\]()>-]/, '').split.length
    reading_time = [(word_count / 200.0).ceil, 1].max

    result = {
      title:            meta['title'],
      meta_description: meta['meta_description'],
      slug:             meta['slug'],
      published_at:     meta['published_at'],
      published_time:   meta['published_time'],
      updated_at:       meta['updated_at'],
      author:           meta['author'] || 'Adrien',
      image:            meta['image'],
      image_credit:     meta['image_credit'],
      excerpt:          meta['excerpt'],
      derby_pairs:       meta['derby_pairs'],
      match_pairs_title: meta['match_pairs_title'],
      match_groups:      meta['match_groups'],
      reading_time:      reading_time,
      dazn_card:         meta.key?('dazn_card') ? meta['dazn_card'] : true
    }
    result[:body] = body_text if with_body
    result
  end

  def render_markdown_with_toc(text)
    renderer = Redcarpet::Render::HTML.new(hard_wrap: false)
    md = Redcarpet::Markdown.new(renderer, tables: true, no_intra_emphasis: true, autolink: false)
    html = md.render(text)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    toc = []
    doc.css('h2').each do |h2|
      heading_text = h2.text.strip
      anchor = heading_text.parameterize
      h2['id'] = anchor
      toc << { text: heading_text, anchor: anchor }
    end
    [doc.to_html.html_safe, toc]
  end
end
