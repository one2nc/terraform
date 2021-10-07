require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "all" do
    user = User.where(username: "ashnehete")[0]
    assert user.password == "alphabeta"
  end
end
