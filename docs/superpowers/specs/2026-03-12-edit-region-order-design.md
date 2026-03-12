# Edit Region Order

## Problem

The NCAA tournament bracket has 4 fixed positions, each labeled with a region name (South, West, East, Midwest). The assignment of labels to positions changes year to year on Selection Sunday. Currently, this mapping is hardcoded in `Team::REGION_NAMES`, requiring a code change and redeploy to update. This feature makes region label assignment admin-configurable at runtime.

## Mental Model

The bracket has 4 structural positions (0, 1, 2, 3) that correspond to fixed locations on the bracket display (top-left, bottom-left, top-right, bottom-right). Region labels are display names assigned to each position. Teams belong to a numbered region (0-3) which determines their bracket position. The label is purely a display concern looked up from the tournament configuration.

## Data Model

### Tournament table

Add a `region_labels` JSON column with default `["South", "West", "East", "Midwest"]`. The array index is the region position (0-3), the value is the display label string.

**Validation:** `region_labels` must be a permutation of `["South", "West", "East", "Midwest"]` -- all 4 present, no duplicates, no other values. Only the ordering can change.

### Team model

- Remove `REGION_NAMES` constant.
- Remove `enum :region` declaration. `team.region` becomes a plain integer column (0-3).
- Remove `self.region_names` class method.
- `placeholder_name_for` uses `Tournament.field_64.region_labels[index / 16]` instead of the removed constant.

### Tournament model

- Add `region_labels` accessor with JSON default.
- Add `NUM_REGIONS = 4` constant to replace uses of `Team.regions.size`.
- `game_slots_for` uses integer region directly. Remove the symbol-to-int conversion (`Team.regions[region] if region.is_a?(Symbol)`).

### Game model

- `region` method returns the integer index (0-3) instead of a symbol name. Display code looks up the label from the tournament.
- Replace `Team.regions.size` with `Tournament::NUM_REGIONS`.
- Replace `Team.region_names` with `(0...Tournament::NUM_REGIONS).to_a`.

### Round model

- `regions` returns `(0...Tournament::NUM_REGIONS).to_a` (position indices) instead of names. Views look up labels from the tournament.

## Admin UI

On the existing `admin/tournaments/show` page, add a "Region Order" section:

- A list showing the 4 region labels in their current order (position 0-3).
- Up/down arrow buttons on each row to reorder.
- Position labels indicating bracket location: 0 = top-left, 1 = bottom-left, 2 = top-right, 3 = bottom-right.
- Save via standard form submission with Turbo, consistent with existing admin patterns.
- Only shown when tournament is in `pre_selection` or `not_started` state. Once the tournament starts, region order is locked.

## Frontend / Display

- `bracket_picker_props` in `ApplicationHelper` adds `regionLabels: tournament.region_labels` to the tournament hash.
- `Round#regions` returns `(0...Tournament::NUM_REGIONS).to_a` for regional rounds. The frontend uses these indices to look up from `regionLabels`.
- CSS classes `region1`-`region4` in `tournament_bracket.css` define fixed bracket positions and stay as-is. Only the label text changes.
- Region label elements (`.region-label`) get their text from `regionLabels[index]` instead of hardcoded names.

## Seeds, Scenarios & Tests

### No changes needed

- `db/seeds.rb` -- assigns `team.region = i / 16` as an integer. Already correct.
- `lib/scenarios/base.rb` -- same integer assignment pattern.

### Test updates

- `test/models/tournament_test.rb` -- replace `Team.east_region` and `Team.regions[:east]` with integer-based region lookup (`Team.where(region: 2)`).
- `test/models/team_test.rb` -- replace `region: :south` symbols with `region: 0`. Update `placeholder_name_for` tests to verify labels come from the tournament.
- `test/system/bracket_picker_test.rb` and `tournament_display_test.rb` -- region label assertions continue to work with default order. Labels come from the tournament record.

### New tests

- Tournament model: validate `region_labels` permutation validation (rejects duplicates, missing values, extra values, non-standard names).
- Tournament model: `region_labels` default is `["South", "West", "East", "Midwest"]`.
- Admin integration: reordering region labels persists correctly.
- Admin integration: reorder UI hidden when tournament is started.
