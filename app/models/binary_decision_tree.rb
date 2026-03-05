module BinaryDecisionTree
  class MarshalledTree
    attr_reader :depth, :decisions, :mask

    def initialize(depth, decisions, mask)
      @depth = depth
      @decisions = decisions
      @mask = mask
    end

    def self.from_tree(tree)
      depth = tree.depth
      decisions = 0
      mask = 0

      (2**tree.depth).times do |i|
        next if i.zero?

        node = tree.at(i)
        unless node.decision.nil?
          mask |= 1 << i
          decisions |= node.decision << i
        end
      end

      new(depth, decisions, mask)
    end

    def to_tree(tree_class: Tree)
      tree = tree_class.new(depth)

      (2**tree.depth).times do |i|
        next if i.zero?

        current_position = 1 << i

        if mask.anybits?(current_position)
          node = tree.at(i)
          node.decision = decisions.nobits?(current_position) ? 0 : 1
        end
      end

      tree
    end

    def ==(other)
      other.class == self.class && other.state == state
    end

    alias eql? ==

    delegate :hash, to: :state

    protected

    def state
      [ depth, decisions, mask ]
    end
  end


  class Node
    LEFT = 0
    RIGHT = 1

    attr_accessor :decision # nil, 0, or 1

    attr_reader :slot, :tree # bit position

    def initialize(tree, slot)
      @tree = tree
      @slot = slot
      @decision = nil
    end

    def value
      case decision
      when LEFT
        left.nil? ? left_position : left.value
      when RIGHT
        right.nil? ? right_position : right.value
      end
    end

    def leaf?
      left.nil? && right.nil?
    end

    def current_depth
      Math.log2(slot).floor + 1
    end

    def parent_position
      (slot.even? ? slot + 1 : slot) / 2
    end

    def left_position
      slot * 2
    end

    def right_position
      left_position + 1
    end

    def parent
      tree.at(parent_position)
    end

    def left
      tree.at(left_position)
    end

    def right
      tree.at(right_position)
    end
  end


  class Tree
    attr_reader :depth

    def initialize(depth, node_class: Node)
      @depth = depth
      @nodes = Array.new(size) { |i| i.zero? ? nil : node_class.new(self, i) }
    end

    def root
      @nodes[1]
    end

    def at(position)
      @nodes[position]
    end

    def size
      2**depth
    end
  end
end
