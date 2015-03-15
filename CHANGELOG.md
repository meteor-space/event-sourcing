Changelog
=========

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
