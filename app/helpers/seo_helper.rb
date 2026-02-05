module SeoHelper
  def meta_title(title)
    content_for(:title) { title }
  end

  def meta_description(description)
    content_for(:description) { description }
  end
end
