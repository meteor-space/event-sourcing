
class Space.cqrs.ProcessManagerRepository

  Dependencies:
    commitStore: 'Space.cqrs.CommitStore'

  find: (ProcessManagerType, processManagerId) ->
    events = @commitStore.getEvents processManagerId
    return new ProcessManagerType processManagerId, events

  save: (processManager, expectedVersion) ->
    changes =
      events: processManager.getEvents()
      commands: processManager.getCommands()
    @commitStore.add changes, processManager.getId(), expectedVersion
