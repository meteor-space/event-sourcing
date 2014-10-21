
class Space.cqrs.AggregateRepository

  @toString: -> 'Space.cqrs.AggregateRepository'

  Dependencies:
    eventStore: 'Space.cqrs.EventStore'

  create: (aggregate) ->
    @eventStore.add aggregate.getEvents(), aggregate.getId(), 0

  find: (AggregateType, aggregateId) ->
    events = @eventStore.getEvents aggregateId
    return new AggregateType aggregateId, events

  save: (aggregate, expectedVersion) ->
    @eventStore.add aggregate.getEvents(), aggregate.getId(), expectedVersion