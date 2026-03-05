require "test_helper"

class BinaryDecisionTreeTest < ActiveSupport::TestCase
  def setup
    @tree = BinaryDecisionTree::Tree.new(3) # Create a tree with depth 3 (7 nodes)
  end

  test "tree initialization" do
    assert_equal 3, @tree.depth
    assert_equal 8, @tree.size # 2^3 nodes (including root at index 0)
    assert_not_nil @tree.root
    assert_equal 1, @tree.root.slot
  end

  test "node relationships" do
    root = @tree.root
    assert_equal 2, root.left_position
    assert_equal 3, root.right_position
    assert_nil root.parent # Root has no parent

    left_child = root.left
    assert_equal root, left_child.parent
    assert_equal 4, left_child.left_position
    assert_equal 5, left_child.right_position

    right_child = root.right
    assert_equal root, right_child.parent
    assert_equal 6, right_child.left_position
    assert_equal 7, right_child.right_position
  end

  test "node depth calculations" do
    assert_equal 1, @tree.root.current_depth
    assert_equal 2, @tree.at(2).current_depth
    assert_equal 2, @tree.at(3).current_depth
    assert_equal 3, @tree.at(4).current_depth
  end

  test "leaf node detection" do
    assert_not @tree.root.leaf?
    assert_not @tree.at(2).leaf?
    assert @tree.at(4).leaf?
    assert @tree.at(7).leaf?
  end

  test "node value calculation" do
    leaf = @tree.at(4)
    assert_nil leaf.value # No decision made yet

    leaf.decision = 0 # Choose left
    assert_equal 8, leaf.value # 2 * 4 (left_position)

    leaf.decision = 1 # Choose right
    assert_equal 9, leaf.value # 2 * 4 + 1 (right_position)
  end

  test "tree marshalling" do
    # Set some decisions in the tree
    @tree.at(4).decision = 0
    @tree.at(5).decision = 1
    @tree.at(2).decision = 0

    # Marshal the tree
    marshalled = BinaryDecisionTree::MarshalledTree.from_tree(@tree)

    # Create a new tree from the marshalled data
    new_tree = marshalled.to_tree

    # Verify the decisions were preserved
    assert_equal 0, new_tree.at(4).decision
    assert_equal 1, new_tree.at(5).decision
    assert_equal 0, new_tree.at(2).decision
  end

  test "node equality" do
    node1 = @tree.at(2)
    node2 = @tree.at(2)
    node3 = @tree.at(3)

    assert_equal node1, node2
    refute_equal node1, node3

    # Nodes from different trees should not be equal
    other_tree = BinaryDecisionTree::Tree.new(3)
    other_node = other_tree.at(2)
    refute_equal node1, other_node
  end

  test "marshalled tree equality" do
    @tree.at(4).decision = 0
    @tree.at(5).decision = 1

    marshalled1 = BinaryDecisionTree::MarshalledTree.from_tree(@tree)
    marshalled2 = BinaryDecisionTree::MarshalledTree.from_tree(@tree)

    assert_equal marshalled1, marshalled2

    # Different trees should not be equal
    other_tree = BinaryDecisionTree::Tree.new(3)
    other_marshalled = BinaryDecisionTree::MarshalledTree.from_tree(other_tree)
    refute_equal marshalled1, other_marshalled
  end
end
