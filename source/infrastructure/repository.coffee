
class Space.eventSourcing.Repository extends Space.Object

  Dependencies:
    commitStore: 'Space.eventSourcing.CommitStore'

  # Optional snapshotter that can be configured via `useSnapshotter`
  _snapshotter: null

  find: (Type, id) ->
    aggregate = @_snapshotter?.getSnapshotOf(Type, id)
    if aggregate?
      remainingEvents = @commitStore.getEvents id, aggregate.getVersion() + 1
      aggregate.replayHistory remainingEvents
    else
      aggregate = Type.createFromHistory @commitStore.getEvents(id)
    return aggregate

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
