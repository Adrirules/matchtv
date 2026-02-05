require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get matches_show_url
    assert_response :success
  end
end
