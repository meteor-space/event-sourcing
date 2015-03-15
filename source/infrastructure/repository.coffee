
class Space.cqrs.Repository extends Space.Object

  Dependencies:
    commitStore: 'Space.cqrs.CommitStore'

  find: (Type, id) ->
    events = @commitStore.getEvents id
    if events.length > 0 then return new Type(id, events) else return null

  save: (instance, expectedVersion) ->

    changes =
      events: instance.getEvents?() ? []
      commands: instance.getCommands?() ? []

    @commitStore.add changes, instance.getId(), expectedVersion
