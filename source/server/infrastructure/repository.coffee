
class Space.eventSourcing.Repository extends Space.Object

  dependencies:
    commitStore: 'Space.eventSourcing.CommitStore'

  # Optional snapshotter that can be configured via `useSnapshotter`
  _snapshotter: null

  find: (Type, id) ->
    aggregate = @_snapshotter?.getSnapshotOf(Type, id)
    if aggregate?
      remainingEvents = @commitStore.getEvents id, aggregate.getVersion() + 1
      if remainingEvents.length > 0
        aggregate.replayHistory remainingEvents
    else
      eventHistory = @commitStore.getEvents(id)
      if eventHistory.length > 0
        aggregate = Type.createFromHistory eventHistory
      else
        throw new Error "No events found for aggregate #{Type}<#{id}>"
    return aggregate

  save: (aggregate) ->
    # Save the changes into the commit store
    changes =
      aggregateType: aggregate.toString()
      events: aggregate.getEvents?() ? []
      commands: aggregate.getCommands?() ? []
    @commitStore.add changes, aggregate.getId(), aggregate.getVersion()
    # When the changes have been committed bump aggregate version
    aggregate._version += 1
    # Make a snapshot if configured
    @_snapshotter?.makeSnapshotOf aggregate

  useSnapshotter: (@_snapshotter) ->
