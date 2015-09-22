Changelog
=========

### 1.3.3
Fixes issues introduced by the new Meteor dependency tracker / package system.

### 1.3.2
Bind command generators in `Space.eventSourcing.Router::mapEvent` to the
router instance like with the `@on` and `@handle` methods.

### 1.3.1
Makes it possible to hook into projection replaying via `Space.eventSourcing.Projection::enterReplayMode`, this hook is now called after
the injected collections have been replaced. This is important for situations
like the Meteor accounts system that writes to a globally accessible collection
instead of the injected one. Now you can override global collections during
replays to establish the same kind of functionality.

### 1.3.0
- Adds `Space.eventSourcing.Router` to reduce the boilerplate that was necessary
to route commands to aggregates.
- Adds the `Guid` value object which is necessary for most event-sourcing projects
- Fixes some minor issues and bugs with snapshotter

### 1.2.3
Added `@on` alias for `@handle` in `Space.eventSourcing.Aggregate` so you can
use the same semantics as in `Space.messaging.Controller`

### 1.2.2
Simplified the `Space.eventSourcing.Aggregate.createFromHistory` method

### 1.2.1
Improvements:
Added two new ways how `Space.eventSourcing.Aggregate` can be created:
- By providing a command with `targetId` property (which is assigned as id)
- Using the new static `Aggregate.createFromHistory` method and providing an
array of historic events. You don't have to provide the id extra there ;-)

### 1.2.0
Improvements:
- Fixes some problematic error messages in aggregates and made it clear that
aggregates can also handle commands, not only events.
- Added `Space.eventSourcing.Projector` which can be used to rebuild certain
projections from all historic events in the event-store.

### 1.1.0
BREAKING CHANGES:
- The `Space.cqrs` namespace is now called `Space.eventSourcing`
- `Space.cqrs.ValueObject` was removed from the project
- `Space.cqrs.ProcessManager` is now `Space.eventSourcing.Process`
- Updated Github repo location to https://github.com/meteor-space/event-sourcing
- The new Meteor package name is `space:event-sourcing`

### 5.1.1
Let `Space.cqrs.Aggregate` extend `Space.Object` to improve compatibility with
Javascript (in addition to Coffeescript).

### 5.1.0
Introduces snapshotting capabilities for `Space.cqrs.Repository` which can
optionally be configured to take snapshots and replay history starting from
a version offset. This greatly improves performance for aggregates which require
many events to flow through, as only a tiny fraction of all events has to be
replayed instead of the whole history.

### 5.0.0
Updates to `space:base@2.1.0` and `space:messaging@1.2.1`, please look at
the breaking changes in these packages to see what changed.

### 4.0.2
Changes:
  * Make construction of aggregates more flexible: You can now pass any number
  of arguments and they will be passed onto the `initialize` method.
  * Save the current version of an aggregate by default. This way you can call
  `@repository.save aggregate` most of the time without having to speciy a version

### 4.0.1
Changes:
  * Move object freezing capability from constructor into `ValueObject::freeze`
  method. For some value objects it doesn't work well to freeze directly after
  setting the fields. For example if something needs to be calculated based on
  the field values, this wouldn't be possible anymore.

### 4.0.0
Breaking Changes:
-----------------
  * Unified `AggregateRepository` and `ProcessManagerRepository` to a single
  class `Space.cqrs.Repository`
  * Renamed `Space.cqrs.CommitsColletion` to `Space.cqrs.Commits`, moved it
  into the server module and simplified its creation code.

Features:
---------
  * Moved the state functionality of process managers into aggregates.
  * Value Objects use `Object.freeze` for basic immutability on creation.

### 3.0.1
Update to latest space:messaging release

### 3.0.0

Breaking Changes:
-----------------
Moves the command and event architecture to its own package `space:messaging`.
The way the fields are defined has changed, please have a look at the integration
tests to see how it works now.

### 2.3.2
Features:
  * Make command handlers overridable for easier testing
  * Adds error message when trying to send non-commands
  * Added insertedAt and publishedAt dates for commits

Bugfixes:
  * Improves event handling of aggregates
  * Only add serializable fields when they are defined

### 2.3.1
Bugfixes:
  * Don't apply the version when process managers handle events

### 2.3.0
Features:
  * Let the infrastructure handle value object ids correctly
  * Removes id check for aggregates for improved flexibility on event handling
  * Adds the #handle method to process managers which is an alias for #replay
