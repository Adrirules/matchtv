require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sitemaps_index_url
    assert_response :success
  end
end
