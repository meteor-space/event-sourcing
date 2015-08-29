
class Space.cqrs.Repository extends Space.Object

  Dependencies:
    commitStore: 'Space.cqrs.CommitStore'

  # Optional snapshotter that can be configured via `useSnapshotter`
  _snapshotter: null

  find: (Type, id) ->
    if @_snapshotter?
      # Get the latest snapshot of the aggregate and replay remaining events
      aggregate = @_snapshotter.getSnapshotOf Type, id
      remainingEvents = @commitStore.getEvents id, aggregate.getVersion() + 1
      aggregate.replayHistory remainingEvents
      return aggregate
    else
      # Get all events for the aggregate and create it directly from history
      events = @commitStore.getEvents id
      if events.length > 0 then return new Type(id, events) else return null

  save: (aggregate, expectedVersion) ->

    # Let the snapshotter do it's work if configured
    @_snapshotter?.makeSnapshotOf aggregate

    # Save the changes into the commit store
    changes =
      events: aggregate.getEvents?() ? []
      commands: aggregate.getCommands?() ? []
    expectedVersion ?= aggregate.getVersion()
    @commitStore.add changes, aggregate.getId(), expectedVersion

  useSnapshotter: (@_snapshotter) ->
