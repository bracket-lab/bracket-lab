# Edit Region Order

## Problem

The NCAA tournament bracket has 4 fixed positions, each labeled with a region name (South, West, East, Midwest). The assignment of labels to positions changes year to year on Selection Sunday. Currently, this mapping is hardcoded in `Team::REGION_NAMES`, requiring a code change and redeploy to update. This feature makes region label assignment admin-configurable at runtime.

## Mental Model

The bracket has 4 structural positions (0, 1, 2, 3) that correspond to fixed locations on the bracket display (top-left, bottom-left, top-right, bottom-right). Region labels are display names assigned to each position. Teams belong to a numbered region (0-3) which determines their bracket position. The label is purely a display concern looked up from the tournament configuration.

## Data Model

### Tournament table

Add a `region_labels` text column with `serialize :region_labels, coder: JSON` in the model. Default `["South", "West", "East", "Midwest"]`. The array index is the region position (0-3), the value is the display label string. Text column with JSON serialization is used because the app runs on SQLite.

The migration sets the database-level default as a JSON string: `default: '["South","West","East","Midwest"]'`. The single existing tournament record gets the default, which matches the current hardcoded order. No data migration is needed.

**Validation:** `region_labels` must be a permutation of `Tournament::REGION_NAMES`. All 4 present, no duplicates, no other values. Only the ordering can change.

### Team model

- Remove `REGION_NAMES` constant.
- Remove `enum :region` declaration. `team.region` becomes a plain integer column (0-3).
- Remove `self.region_names` class method.
- `placeholder_name_for` uses `Tournament.field_64.region_labels[index / 16]` instead of the removed constant.

### Tournament model

- Add `REGION_NAMES = ["South", "West", "East", "Midwest"].freeze` -- the canonical set of allowed region labels. Used as the default value and the validation reference.
- Add `NUM_REGIONS = 4` constant to replace uses of `Team.regions.size`.
- Add `serialize :region_labels, coder: JSON` with default from `REGION_NAMES`.
- `game_slots_for` takes integer region only. Remove the symbol-to-int conversion (`Team.regions[region] if region.is_a?(Symbol)`) since there are no more enum symbols.
- Replace `Team.regions.size` with `NUM_REGIONS`.

### Game model

- `region` method returns the label string by looking up from `tournament.region_labels` using the computed index. Note: the return type changes from Symbol to String, but no code currently calls this method from views. `Game` already has private `tournament` access via `tree.tournament`.
- Replace `Team.regions.size` with `Tournament::NUM_REGIONS`.
- Replace `Team.region_names` with `tournament.region_labels`.

### Round model

- `regions` method uses `Current.tournament.region_labels` instead of `Team.region_names`. This preserves the return type as an array of strings and the zero-argument signature, so all downstream consumers (ERB partials, React components, `bracket_picker_props`) need zero changes.

## Admin UI

On the existing `admin/tournaments/show` page, add a "Region Order" section:

- A list showing the 4 region labels in their current order (position 0-3).
- Up/down arrow buttons on each row to reorder.
- Position labels indicating bracket location: 0 = top-left, 1 = bottom-left, 2 = top-right, 3 = bottom-right.
- Save via standard form submission with Turbo, consistent with existing admin patterns.
- Add a dedicated `update_region_labels` action to `Admin::TournamentsController` with a corresponding route (member action).
- Only shown when tournament is in `pre_selection` or `not_started` state. Once the tournament starts, region order is locked.

## Frontend / Display

Because `Round#regions` continues to return label strings (now sourced from tournament instead of the Team constant), no React or ERB changes are needed for rendering:

- `Region.tsx` receives the label string via `region` prop and renders it directly -- no change.
- `_round.html.erb` iterates `round.regions` as label strings and passes `region_name:` to `_region.html.erb` -- no change.
- `_region.html.erb` renders `region_name` as the label text -- no change.
- CSS classes `region1`-`region4` in `tournament_bracket.css` define fixed bracket positions and stay as-is.

The `bracket_picker_props` helper passes `round.regions` (now tournament-sourced labels) through the existing `regions` key in round data. No new key is needed.

## Admin Team Views

These views reference `Team::REGION_NAMES` and must be updated:

- `admin/teams/index.html.erb` -- iterates `Team::REGION_NAMES` to group teams by region. Change to iterate `Current.tournament.region_labels.each_with_index` and compare using integer region index (`t.region == region_index`).
- `admin/teams/import_preview.html.erb` -- same pattern. Iterate `Current.tournament.region_labels.each_with_index` and compare `p[:team].region == region_index` (integer-to-integer, not string comparison).

## Seeds, Scenarios & Tests

### No changes needed

- `db/seeds.rb` -- assigns `team.region = i / 16` as an integer. Already correct.
- `lib/scenarios/base.rb` -- same integer assignment pattern.
- Tournament fixtures -- omitting `region_labels` relies on the database default, which is correct.

### Test updates

- `test/models/tournament_test.rb` -- replace `Team.east_region` and `Team.regions[:east]` with integer-based region lookup (`Team.where(region: 2)` and integer `2`). Also replace all symbol-based `round_for` calls (e.g., `:midwest`) with integer arguments.
- `test/models/team_test.rb` -- replace `region: :south` symbol (line 106) with `region: 0`. Update `placeholder_name_for` tests to verify labels come from the tournament.
- `test/system/bracket_picker_test.rb` and `tournament_display_test.rb` -- region label assertions continue to work since the default label order matches the current hardcoded order.

### New tests

- Tournament model: validate `region_labels` permutation validation (rejects duplicates, missing values, extra values, non-standard names; accepts any permutation).
- Tournament model: `region_labels` default is `["South", "West", "East", "Midwest"]`.
- Admin integration: reordering region labels persists correctly.
- Admin integration: reorder UI hidden when tournament is started.
