
class Space.cqrs.SagaRepository

  @toString: -> 'Space.cqrs.SagaRepository'

  Dependencies:
    commitStore: 'Space.cqrs.CommitStore'

  find: (SagaType, sagaId) ->
    events = @commitStore.getEvents sagaId
    return new SagaType sagaId, events

  save: (saga) ->

    changes =
      events: saga.getEvents()
      commands: saga.getCommands()

    console.log "saga:", saga.getId(), saga.getVersion()

    @commitStore.add changes, saga.getId(), saga.getVersion()