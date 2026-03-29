class BlogController < ApplicationController
  BLOG_PATH = Rails.root.join('app', 'content', 'blog')

  def index
    @articles = all_articles
    @page_title = "Blog football — Guides et analyses | Coup d'Envoi TV"
    @page_desc  = "Guides pratiques, comparatifs d'abonnements et analyses football rédigés par Adrien pour ne rater aucun match en 2026."
    expires_in 1.hour, public: true
  end

  def show
    @article = load_article(params[:slug])
    render "errors/not_found", status: :not_found and return unless @article
    @page_title  = @article[:title]
    @page_desc   = @article[:meta_description]
    @article_html, @toc = render_markdown_with_toc(@article[:body])
    expires_in 1.hour, public: true
  end

  private

  def all_articles
    Dir.glob(BLOG_PATH.join('*.md')).filter_map { |f| parse_file(f) }
       .sort_by { |a| a[:published_at] }.reverse
  end

  def load_article(slug)
    file = BLOG_PATH.join("#{slug}.md")
    return nil unless File.exist?(file)
    parse_file(file, with_body: true)
  end

  def parse_file(path, with_body: false)
    raw = File.read(path)
    return nil unless raw.start_with?('---')
    parts = raw.split('---', 3)
    return nil if parts.length < 3
    meta = YAML.safe_load(parts[1], permitted_classes: [Date]) rescue {}
    result = {
      title:            meta['title'],
      meta_description: meta['meta_description'],
      slug:             meta['slug'],
      published_at:     meta['published_at'],
      author:           meta['author'] || 'Adrien',
      image:            meta['image'],
      excerpt:          meta['excerpt']
    }
    result[:body] = parts[2].strip if with_body
    result
  end

  def render_markdown_with_toc(text)
    renderer = Redcarpet::Render::HTML.new(hard_wrap: false, safe_links_only: true)
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
