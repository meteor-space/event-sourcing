
class Space.cqrs.Repository extends Space.Object

  Dependencies:
    commitStore: 'Space.cqrs.CommitStore'

  find: (Type, id) ->
    events = @commitStore.getEvents id
    if events.length > 0 then return new Type(id, events) else return null

  save: (aggregate, expectedVersion) ->

    changes =
      events: aggregate.getEvents?() ? []
      commands: aggregate.getCommands?() ? []

    expectedVersion ?= aggregate.getVersion()

    @commitStore.add changes, aggregate.getId(), expectedVersion
