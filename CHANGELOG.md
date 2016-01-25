Changelog
=========

## 3.0.0

### New Features

#### Snapshotting upgrade
- Now handled by the module automatically, default to caching the state every 10 versions.
- Configure using:
  - `Configuration.eventSourcing.snapshotting.enabled = true` or
  
  `SPACE_ES_SNAPSHOTTING_ENABLED='true'`
  - `Configuration.eventSourcing.snapshotting.frequency = 20`
  or
  
  `SPACE_ES_SNAPSHOTTING_FREQUENCY=20`     
  - `SPACE_ES_SNAPSHOTTING_COLLECTION_NAME='my_collection'`

#### New helpers
- `Aggregate::_eventPropsFromCommand(command)` is an internal helper function
 eliminating the boilerplate of mapping `targetId` from the command to `sourceId`
 and manually setting the `version` prop.
 
#### Module
- This package now mixes in specific interfaces `Routers` and `Projections`
for better clarity in your modules/application that depends on Space.eventSourcing.

#### Router
Events can be automatically routed to processes and aggregates based on a correlation
 property, negating the need for lookup collections:

```javascript
Space.eventSourcing.Router.extend(Space.accounts, 'RegistrationsRouter', {

  aggregate: Space.accounts.Registration,
  initializingCommand: Space.accounts.Register,

  routeEvents: [
    Space.accounts.UserCreated,
    Space.accounts.UserCreationFailed,
    Space.accounts.AccountCreated
  ],

  eventCorrelationProperty: 'registrationId'

});
```

#### Commit Publisher
The state of any Commit Publish action is now being managed, with any errors
 thrown while processing are caught and used to fail the attempt.
 There's also a timeout option to autofail the attempt in the case where a 
 problem occurs without an error being thrown. This defaults to 60 seconds
 but can be configured using the ENV or Module Config APIs
 
 - `SPACE_ES_COMMIT_PROCESSING_TIMEOUT=2000` or 
 `Configuration.eventSourcing.commitProcessing.timeout = 2000`
 
#### Domain Error handling
Now when domain exceptions are thrown in an aggregate, the router publishes a
 special event `Space.domain.Exception` that can be subscribed to and used for
  process integration. The event has two custom properties `thrower` and `error`.

### Breaking Changes
- Must be running Meteor 1.2.0.1 or later.

#### Dependencies forcing API changes
- This version uses space:base 4.x which includes breaking changes. 
Please see the [changelog](https://github.com/meteor-space/base/blob/master/CHANGELOG.md).
- This version uses space:messaging 3.x which includes breaking changes. 
Please see the [changelog](https://github.com/meteor-space/messaging/blob/master/CHANGELOG.md).

#### Commits Collection
- Module now manages the commits collection
- Instead of passing in a collection, use the Configuration and/or ENVs.
- Default collection name has been changed from space_cqrs_commitStore
- Events are now persisted in a query-friendly format! Prior to this the data was
stored in a JSON string which was optimal for persistence, but you would have to
maintain a projection in order to query the historical data. Moving from 2.x to
 3.x will require data migration, but we feel this was necessary and will be
  worthwhile for the huge gain in querying capability.

#### `Projector` and `Projection` API changes 
- `Projector` => `ProjectionRebuilder`
- `ProjectionRebuilder::replay(options)` => `rebuild(projections, options)`
- `Projection::enterReplayMode()` => `enterRebuildMode()`
- `Projection::exitReplayMode()` => `exitRebuildMode()`

*Thanks to all the new people on the team who made this awesome release possible:*

- [Rhys Bartels-Waller](https://github.com/rhyslbw)
- [Darko Mijić](https://github.com/darko-mijic)
- [Adam Desivi](https://github.com/qejk)

:clap:

## 2.1.0
**CONTINUED BREAKING CHANGES**
- `Aggregate::handlers` was now split up into `eventMap` and `commandMap`

## 2.0.0
**BREAKING CHANGES**
- Updates dependencies to the new major versions `space:base@3.1.0` and
`space:messaging@2.1.0`. Take look at the changelogs there to see what is
different now.
- Removed the static api for aggregates to register event and command handlers.
Now you have to define a `handlers: -> { My.awesome.Event: -> }` method on the
aggregate class which returns a map of handlers.
- The static `FIELDS` property of aggregates was refactored to be on the prototype

As always, take a look at the tests to see the current api in action.

## 1.4.0
**Bugfixes:**
- Keep minimal Meteor version at 1.0
- Fixes versioning of events in the commit store

**Improvements:**
- Allow router event mappings to return null if no command should be routed
- Adds better error message if router cant find a certain aggregate

**Feature: Distributed Commit Store**
The commit store and publishing of events & commands has been greatly
improved and simplified. Everything is distributed by default, simply
by sharing a MongoDB collection between apps, used for the commits.
The commit publish now observes the commits collection and thus also
handles changes made in other apps (distribution). The commit store and
publisher ensure that a single application only handles a commit once
even if it has multiple processes running (via `find-and-modify`).

## 1.3.3
Fixes issues introduced by the new Meteor dependency tracker / package system.

## 1.3.2
Bind command generators in `Space.eventSourcing.Router::mapEvent` to the
router instance like with the `@on` and `@handle` methods.

## 1.3.1
Makes it possible to hook into projection replaying via `Space.eventSourcing.Projection::enterReplayMode`, this hook is now called after
the injected collections have been replaced. This is important for situations
like the Meteor accounts system that writes to a globally accessible collection
instead of the injected one. Now you can override global collections during
replays to establish the same kind of functionality.

## 1.3.0
- Adds `Space.eventSourcing.Router` to reduce the boilerplate that was necessary
to route commands to aggregates.
- Adds the `Guid` value object which is necessary for most event-sourcing projects
- Fixes some minor issues and bugs with snapshotter

## 1.2.3
Added `@on` alias for `@handle` in `Space.eventSourcing.Aggregate` so you can
use the same semantics as in `Space.messaging.Controller`

## 1.2.2
Simplified the `Space.eventSourcing.Aggregate.createFromHistory` method

## 1.2.1
Improvements:
Added two new ways how `Space.eventSourcing.Aggregate` can be created:
- By providing a command with `targetId` property (which is assigned as id)
- Using the new static `Aggregate.createFromHistory` method and providing an
array of historic events. You don't have to provide the id extra there ;-)

## 1.2.0
Improvements:
- Fixes some problematic error messages in aggregates and made it clear that
aggregates can also handle commands, not only events.
- Added `Space.eventSourcing.Projector` which can be used to rebuild certain
projections from all historic events in the event-store.

## 1.1.0
BREAKING CHANGES:
- The `Space.cqrs` namespace is now called `Space.eventSourcing`
- `Space.cqrs.ValueObject` was removed from the project
- `Space.cqrs.ProcessManager` is now `Space.eventSourcing.Process`
- Updated Github repo location to https://github.com/meteor-space/event-sourcing
- The new Meteor package name is `space:event-sourcing`

## 5.1.1
Let `Space.cqrs.Aggregate` extend `Space.Object` to improve compatibility with
Javascript (in addition to Coffeescript).

## 5.1.0
Introduces snapshotting capabilities for `Space.cqrs.Repository` which can
optionally be configured to take snapshots and replay history starting from
a version offset. This greatly improves performance for aggregates which require
many events to flow through, as only a tiny fraction of all events has to be
replayed instead of the whole history.

## 5.0.0
Updates to `space:base@2.1.0` and `space:messaging@1.2.1`, please look at
the breaking changes in these packages to see what changed.

## 4.0.2
Changes:
  * Make construction of aggregates more flexible: You can now pass any number
  of arguments and they will be passed onto the `initialize` method.
  * Save the current version of an aggregate by default. This way you can call
  `@repository.save aggregate` most of the time without having to speciy a version

## 4.0.1
Changes:
  * Move object freezing capability from constructor into `ValueObject::freeze`
  method. For some value objects it doesn't work well to freeze directly after
  setting the fields. For example if something needs to be calculated based on
  the field values, this wouldn't be possible anymore.

## 4.0.0
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

## 3.0.1
Update to latest space:messaging release

## 3.0.0

Breaking Changes:
-----------------
Moves the command and event architecture to its own package `space:messaging`.
The way the fields are defined has changed, please have a look at the integration
tests to see how it works now.

## 2.3.2
Features:
  * Make command handlers overridable for easier testing
  * Adds error message when trying to send non-commands
  * Added insertedAt and publishedAt dates for commits

Bugfixes:
  * Improves event handling of aggregates
  * Only add serializable fields when they are defined

## 2.3.1
Bugfixes:
  * Don't apply the version when process managers handle events

## 2.3.0
Features:
  * Let the infrastructure handle value object ids correctly
  * Removes id check for aggregates for improved flexibility on event handling
  * Adds the #handle method to process managers which is an alias for #replay
