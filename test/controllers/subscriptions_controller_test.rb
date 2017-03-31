require 'test_helper'

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "should get stripe_checkout" do
    get subscriptions_stripe_checkout_url
    assert_response :success
  end

  test "should get plans" do
    get subscriptions_plans_url
    assert_response :success
  end

  test "should get index" do
    get subscriptions_index_url
    assert_response :success
  end

end
