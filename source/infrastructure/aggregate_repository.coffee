
class Space.cqrs.AggregateRepository

  @toString: -> 'Space.cqrs.AggregateRepository'

  Dependencies:
    commitStore: 'Space.cqrs.CommitStore'

  find: (AggregateType, aggregateId) ->

    events = @commitStore.getEvents aggregateId
    return new AggregateType aggregateId, events

  save: (aggregate, expectedVersion) ->

    changes = events: aggregate.getEvents()
    @commitStore.add changes, aggregate.getId(), expectedVersion