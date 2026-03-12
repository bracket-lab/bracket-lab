# Edit Region Order Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make tournament region labels admin-configurable instead of hardcoded, eliminating redeployments on Selection Sunday.

**Architecture:** Add a `region_labels` text column (JSON-serialized) to the `tournaments` table. Remove the Team enum and `REGION_NAMES` constant. The canonical set of labels moves to `Tournament::REGION_NAMES`. `Round#regions` returns label strings from `Current.tournament.region_labels` preserving existing signatures for all downstream consumers.

**Tech Stack:** Rails 8.1, SQLite, Turbo/Stimulus, Minitest

**Spec:** `docs/superpowers/specs/2026-03-12-edit-region-order-design.md`

---

## File Map

**Create:**
- `db/migrate/YYYYMMDDHHMMSS_add_region_labels_to_tournaments.rb`

**Modify:**
- `app/models/tournament.rb` — add `REGION_NAMES`, `NUM_REGIONS`, `serialize`, validation, `game_slots_for` cleanup
- `app/models/team.rb` — remove `REGION_NAMES`, `enum :region`, `region_names`; update `placeholder_name_for`
- `app/models/game.rb` — update `region` method to use `tournament.region_labels`
- `app/models/round.rb` — update `regions` to use `Current.tournament.region_labels`
- `app/controllers/admin/tournaments_controller.rb` — add `update_region_labels` action
- `config/routes.rb` — add `update_region_labels` member route
- `app/views/admin/tournaments/show.html.erb` — add region order editor section
- `app/views/admin/teams/index.html.erb` — replace `Team::REGION_NAMES` with `Current.tournament.region_labels`
- `app/views/admin/teams/import_preview.html.erb` — same replacement
- `test/models/tournament_test.rb` — replace enum/symbol usage with integers
- `test/models/team_test.rb` — replace `:south` symbols with integers
- `db/schema.rb` — auto-updated by migration

---

## Chunk 1: Data Model

### Task 1: Migration — add region_labels to tournaments

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_add_region_labels_to_tournaments.rb`

- [ ] **Step 1: Generate migration**

Run: `bin/rails generate migration AddRegionLabelsToTournaments`

- [ ] **Step 2: Write migration**

```ruby
class AddRegionLabelsToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :region_labels, :text, default: '["South","West","East","Midwest"]', null: false
  end
end
```

- [ ] **Step 3: Run migration**

Run: `bin/rails db:migrate`
Expected: schema.rb updated with `region_labels` text column on tournaments table.

- [ ] **Step 4: Commit**

```bash
git add db/migrate/*_add_region_labels_to_tournaments.rb db/schema.rb
git commit -m "Add region_labels column to tournaments table"
```

### Task 2: Tournament model — constants, serialization, validation

**Files:**
- Modify: `app/models/tournament.rb:1-9`
- Test: `test/models/tournament_test.rb`

- [ ] **Step 1: Write failing tests for region_labels**

Add to `test/models/tournament_test.rb`:

```ruby
test "region_labels defaults to standard order" do
  assert_equal ["South", "West", "East", "Midwest"], @tournament.region_labels
end

test "region_labels accepts any permutation" do
  @tournament.region_labels = ["East", "West", "South", "Midwest"]
  assert @tournament.valid?
end

test "region_labels rejects duplicates" do
  @tournament.region_labels = ["South", "South", "East", "Midwest"]
  assert_not @tournament.valid?
  assert_includes @tournament.errors[:region_labels], "must be a permutation of the four region names"
end

test "region_labels rejects missing values" do
  @tournament.region_labels = ["South", "West", "East"]
  assert_not @tournament.valid?
  assert_includes @tournament.errors[:region_labels], "must be a permutation of the four region names"
end

test "region_labels rejects extra values" do
  @tournament.region_labels = ["South", "West", "East", "Midwest", "North"]
  assert_not @tournament.valid?
  assert_includes @tournament.errors[:region_labels], "must be a permutation of the four region names"
end

test "region_labels rejects non-standard names" do
  @tournament.region_labels = ["South", "West", "East", "North"]
  assert_not @tournament.valid?
  assert_includes @tournament.errors[:region_labels], "must be a permutation of the four region names"
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/models/tournament_test.rb`
Expected: 6 new tests fail (no `region_labels` method yet on model, no validation).

- [ ] **Step 3: Add constants, serialization, and validation to Tournament**

In `app/models/tournament.rb`, add after line 3 (`NUM_ROUNDS = 6`):

```ruby
REGION_NAMES = ["South", "West", "East", "Midwest"].freeze
NUM_REGIONS = 4

serialize :region_labels, coder: JSON

validate :region_labels_must_be_valid_permutation

# ... (at bottom of private section)

def region_labels_must_be_valid_permutation
  unless region_labels.is_a?(Array) && region_labels.sort == REGION_NAMES.sort
    errors.add(:region_labels, "must be a permutation of the four region names")
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bin/rails test test/models/tournament_test.rb`
Expected: All tests pass including 6 new ones.

- [ ] **Step 5: Commit**

```bash
git add app/models/tournament.rb test/models/tournament_test.rb
git commit -m "Add region_labels to Tournament with validation"
```

### Task 3: Update game_slots_for to use integer regions only

**Files:**
- Modify: `app/models/tournament.rb:73-87`

- [ ] **Step 1: Update game_slots_for**

Replace `app/models/tournament.rb` lines 73-87:

```ruby
def game_slots_for(round_number, region = nil)
  game_ids = tree.game_slots_for(round_number)

  if !region.nil? && game_ids.size >= NUM_REGIONS
    slice_size = game_ids.size / NUM_REGIONS
    slices = game_ids.each_slice(slice_size).to_a
    slices[region]
  else
    game_ids
  end
end
```

Note: `!region.nil?` is functionally equivalent to `region.present?` for integers (including `0`), but better expresses the intent that `nil` means "all regions" while any integer is a valid region index.

- [ ] **Step 2: Commit**

```bash
git add app/models/tournament.rb
git commit -m "Simplify game_slots_for to accept integer region only"
```

### Task 4: Remove Team enum, update Game/Round, fix tests

> **Note:** Tasks 4 changes Team, Game, Round models and fixes all tests in one atomic step so the test suite stays green after the commit.

**Files:**
- Modify: `app/models/team.rb:1-20`
- Modify: `app/models/game.rb:19-28`
- Modify: `app/models/round.rb:31-33`
- Modify: `test/models/tournament_test.rb:67-91`
- Modify: `test/models/team_test.rb:8-12,87-110`

- [ ] **Step 1: Update Team model**

Replace `app/models/team.rb` contents:

```ruby
class Team < ApplicationRecord
  SEED_ORDER = [ 1, 16, 8, 9, 5, 12, 4, 13, 6, 11, 3, 14, 7, 10, 2, 15 ].freeze

  validates :name, presence: true, length: { maximum: 15 }, uniqueness: true

  default_scope { order(starting_slot: :asc) }

  def self.placeholder_name_for(starting_slot)
    index = starting_slot - 64
    region_label = Tournament.field_64.region_labels[index / 16]
    seed = seed_for_slot(starting_slot)
    "#{region_label} #{seed}"
  end

  def self.seed_for_slot(starting_slot)
    SEED_ORDER[starting_slot % 16]
  end

  def first_game
    Tournament.field_64.tree.at(starting_slot / 2)
  end

  def still_playing?
    Rails.cache.fetch("#{Tournament.field_64.cache_key}/#{starting_slot}/still_playing") do
      dts = Tournament.field_64.decision_team_slots
      slot = starting_slot / 2
      until dts[slot].nil?
        return false if dts[slot] != starting_slot

        slot /= 2
      end
      true
    end
  end

  def eliminated?
    !still_playing?
  end
end
```

- [ ] **Step 2: Update Game#region**

Replace `app/models/game.rb` lines 19-28:

```ruby
def region
  game_slots = tree.game_slots_for(round_number)
  return nil if game_slots.size < Tournament::NUM_REGIONS

  slice_size = game_slots.size / Tournament::NUM_REGIONS
  slices = game_slots.each_slice(slice_size).to_a
  region_index = (0...Tournament::NUM_REGIONS).find { |idx| slices[idx].include?(slot) }
  region_index && tournament.region_labels[region_index]
end
```

- [ ] **Step 3: Update Round#regions**

Replace `app/models/round.rb` lines 31-33:

```ruby
def regions
  Current.tournament.region_labels if [ "Final Four", "Champion" ].exclude?(name)
end
```

- [ ] **Step 4: Fix tournament_test.rb**

Replace `test/models/tournament_test.rb` lines 67-75 (`round_for calculations` test):

```ruby
test "round_for calculations" do
  exp_games = [ 1, 8, 5, 4, 6, 3, 7, 2 ].map do |seed|
    Team.where(region: 2).find_by!(seed:).first_game
  end

  assert_equal exp_games.map(&:slot), @tournament.round_for(1, 2).map(&:slot)
end
```

Replace lines 86-91 (`round_for other rounds` test):

```ruby
test "round_for other rounds" do
  (2..4).each do |round|
    exp_games = @tournament.round_for(round - 1, 3).map(&:next_game).uniq
    assert_equal exp_games.map(&:slot), @tournament.round_for(round, 3).map(&:slot)
  end
end
```

- [ ] **Step 5: Fix team_test.rb**

Replace `test/models/team_test.rb` lines 8-12 (`region names` test):

```ruby
test "region labels come from tournament" do
  labels = Tournament.field_64.region_labels
  assert_equal 4, labels.size
  labels.each { |label| assert label.is_a?(String) }
end
```

Replace line 106 (`region: :south` → `region: 0`):

```ruby
      region: 0
```

- [ ] **Step 6: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add app/models/team.rb app/models/game.rb app/models/round.rb test/models/tournament_test.rb test/models/team_test.rb
git commit -m "Remove Team enum, update Game/Round to use tournament region_labels"
```

---

## Chunk 2: Admin UI and Views

### Task 5: Update admin team views

**Files:**
- Modify: `app/views/admin/teams/index.html.erb:12-16`
- Modify: `app/views/admin/teams/import_preview.html.erb:8-20`

- [ ] **Step 1: Update admin teams index**

Replace `app/views/admin/teams/index.html.erb` lines 12-16:

```erb
    <% Current.tournament.region_labels.each_with_index do |label, region_index| %>
      <div class="mb-8">
        <h2 class="text-lg font-semibold mb-3"><%= label %></h2>
        <div>
          <% @teams.select { |t| t.region == region_index }.each_with_index do |team, i| %>
```

Also replace line 21 closing (`<% end %>` for `REGION_NAMES`): no change needed, the `each_with_index` end tag stays.

- [ ] **Step 2: Update admin teams import_preview**

Replace `app/views/admin/teams/import_preview.html.erb` lines 8-10:

```erb
      <% Current.tournament.region_labels.each_with_index do |label, region_index| %>
        <div class="mb-4">
          <h3 class="text-sm font-semibold text-gray-500 uppercase mb-2"><%= label %></h3>
```

Replace line 20:

```erb
              <% @preview.select { |p| p[:team].region == region_index }.each do |entry| %>
```

- [ ] **Step 3: Run test suite**

Run: `bin/rails test`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/views/admin/teams/index.html.erb app/views/admin/teams/import_preview.html.erb
git commit -m "Update admin team views to use tournament region_labels"
```

### Task 6: Add route and controller action for region label reordering

**Files:**
- Modify: `config/routes.rb:13-16`
- Modify: `app/controllers/admin/tournaments_controller.rb`

- [ ] **Step 1: Add route**

In `config/routes.rb`, add to the tournament resource block (after line 15):

```ruby
      post :update_region_labels, on: :member
```

- [ ] **Step 2: Add controller action**

Add to `app/controllers/admin/tournaments_controller.rb` before the `edit` method:

```ruby
  def update_region_labels
    tournament = Current.tournament
    new_labels = params[:region_labels]

    if tournament.update(region_labels: new_labels)
      redirect_to admin_tournament_path, notice: "Region order updated"
    else
      redirect_to admin_tournament_path, alert: tournament.errors.full_messages.to_sentence
    end
  end
```

- [ ] **Step 3: Commit**

```bash
git add config/routes.rb app/controllers/admin/tournaments_controller.rb
git commit -m "Add update_region_labels route and controller action"
```

### Task 7: Add region order editor to tournament show page

**Files:**
- Modify: `app/views/admin/tournaments/show.html.erb`

- [ ] **Step 1: Add region order section**

Add after the closing `</div>` of the action buttons div (after line 20) and before the grid div (line 23):

```erb
    <% unless Current.tournament.started? %>
      <div class="mb-6 p-4 bg-base-200 rounded-lg">
        <h2 class="text-lg font-semibold mb-3">Region Order</h2>
        <p class="text-sm text-gray-500 mb-3">Drag position labels show bracket placement: 1=top-left, 2=bottom-left, 3=top-right, 4=bottom-right</p>
        <div class="space-y-2">
          <% Current.tournament.region_labels.each_with_index do |label, index| %>
            <div class="flex items-center gap-3 p-2 bg-white rounded shadow-sm">
              <span class="text-sm font-mono text-gray-400 w-6"><%= index + 1 %></span>
              <span class="flex-grow font-medium"><%= label %></span>
              <div class="flex gap-1">
                <% if index > 0 %>
                  <%= button_to update_region_labels_admin_tournament_path, method: :post, class: "btn btn-xs btn-ghost", params: { region_labels: Current.tournament.region_labels.dup.tap { |a| a[index], a[index - 1] = a[index - 1], a[index] } } do %>
                    &#9650;
                  <% end %>
                <% else %>
                  <span class="btn btn-xs btn-ghost invisible">&#9650;</span>
                <% end %>
                <% if index < 3 %>
                  <%= button_to update_region_labels_admin_tournament_path, method: :post, class: "btn btn-xs btn-ghost", params: { region_labels: Current.tournament.region_labels.dup.tap { |a| a[index], a[index + 1] = a[index + 1], a[index] } } do %>
                    &#9660;
                  <% end %>
                <% else %>
                  <span class="btn btn-xs btn-ghost invisible">&#9660;</span>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
```

- [ ] **Step 2: Verify in browser**

Run: `bin/dev`
Navigate to admin tournament page. Verify:
- Region order section shows 4 labels with up/down arrows
- Clicking arrows reorders and persists
- Section is hidden when tournament is started

- [ ] **Step 3: Commit**

```bash
git add app/views/admin/tournaments/show.html.erb
git commit -m "Add region order editor to admin tournament page"
```

### Task 8: Add integration tests for region order admin

**Files:**
- Test: `test/controllers/admin/tournaments_controller_test.rb` (create if doesn't exist)

- [ ] **Step 1: Write integration tests**

Create `test/controllers/admin/tournaments_controller_test.rb`:

```ruby
require "test_helper"

class Admin::TournamentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "update_region_labels reorders labels" do
    new_order = ["East", "West", "South", "Midwest"]
    post update_region_labels_admin_tournament_path, params: { region_labels: new_order }

    assert_redirected_to admin_tournament_path
    assert_equal new_order, Tournament.field_64.reload.region_labels
  end

  test "update_region_labels rejects invalid permutation" do
    post update_region_labels_admin_tournament_path, params: { region_labels: ["South", "South", "East", "Midwest"] }

    assert_redirected_to admin_tournament_path
    assert_equal "Region labels must be a permutation of the four region names", flash[:alert]
  end

  test "region order section visible when pre_selection" do
    get admin_tournament_path
    assert_response :success
    assert_select "h2", text: "Region Order"
  end

  test "region order section hidden when started" do
    Tournament.field_64.update_column(:state, Tournament.states[:in_progress])
    get admin_tournament_path
    assert_response :success
    assert_select "h2", text: "Region Order", count: 0
  end
end
```

- [ ] **Step 2: Run tests**

Run: `bin/rails test test/controllers/admin/tournaments_controller_test.rb`
Expected: All 4 tests pass.

- [ ] **Step 3: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/controllers/admin/tournaments_controller_test.rb
git commit -m "Add integration tests for region order admin"
```

### Task 9: Final verification

- [ ] **Step 1: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass (including system tests).

- [ ] **Step 2: Run system tests**

Run: `bin/rails test:system`
Expected: All system tests pass. Region labels display correctly with default order.

- [ ] **Step 3: Verify no remaining references to removed code**

Run: `grep -rn "Team::REGION_NAMES\|Team\.region_names\|Team\.regions\|enum :region\|REGION_NAMES" app/ lib/ test/ --include="*.rb" --include="*.erb"`
Expected: No matches (except `Tournament::REGION_NAMES` which is the new canonical location).
