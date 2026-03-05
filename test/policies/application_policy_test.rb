require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @record = brackets(:one)
  end

  test "requires authenticated user" do
    assert_raises Pundit::NotAuthorizedError do
      ApplicationPolicy.new(nil, @record)
    end
  end

  test "default permissions are false" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.new?
    assert_not policy.update?
    assert_not policy.edit?
    assert_not policy.destroy?
  end

  test "new? delegates to create?" do
    policy = ApplicationPolicy.new(@user, @record)
    policy.define_singleton_method(:create?) { true }

    assert policy.new?
  end

  test "edit? delegates to update?" do
    policy = ApplicationPolicy.new(@user, @record)
    policy.define_singleton_method(:update?) { true }

    assert policy.edit?
  end

  test "scope requires resolve implementation" do
    scope = ApplicationPolicy::Scope.new(@user, Bracket)

    assert_raises NoMethodError do
      scope.resolve
    end
  end
end
