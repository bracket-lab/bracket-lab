require "test_helper"

class PwaControllerTest < ActionDispatch::IntegrationTest
  test "manifest returns JSON" do
    get pwa_manifest_url(format: :json)
    assert_response :success
    assert_equal "application/json", response.media_type

    manifest = JSON.parse(response.body)
    assert_equal "Bracket Lab", manifest["name"]
    assert manifest["icons"].any? { |i| i["sizes"] == "192x192" }
    assert manifest["icons"].any? { |i| i["sizes"] == "512x512" }
  end

  test "service worker returns JavaScript" do
    get pwa_service_worker_url
    assert_response :success
    assert_equal "text/javascript", response.media_type
  end
end
