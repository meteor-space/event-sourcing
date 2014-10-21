
globalNamespace = this

class Space.cqrs.EventStore

  @toString: -> 'Space.cqrs.EventStore'

  Dependencies:
    eventsCollection: 'Space.cqrs.EventsCollection'
    eventBus: 'Space.cqrs.EventBus'

  constructor: -> @globalNamespace = globalNamespace

  add: (events, aggregateId, expectedVersion) ->

    # only continue if there actually ARE events to be added
    if !events? or events.length is 0 then return

    # fetch last inserted batch to get the current version
    lastBatch = @eventsCollection.findOne(
      { aggregateId: aggregateId }, # selector
      { sort: ['version', 'desc'], fields: { version: 1 } } # options
    )

    if lastBatch?
      # take version of last existing batch
      currentVersion = lastBatch.version
    else
      # the aggregate didnt exist before
      currentVersion = 0

    if currentVersion is expectedVersion

      newVersion = currentVersion + 1

      # insert a batch of events as new version
      @eventsCollection.insert {
        aggregateId: aggregateId
        version: newVersion
        events: events
      }

      # publish added events to the world
      for event in events
        event.version = newVersion
        @eventBus.publish event

    else

      # concurrency exception
      throw new Error "Expected aggregate <#{aggregateId}> to be at version
                      #{expectedVersion} but was on #{currentVersion}"

  getEvents: (aggregateId) ->

    events = []

    batches = @eventsCollection.find(
      { aggregateId: aggregateId }, # selector
      { sort: ['version', 'asc'] } # options
    )

    batches.forEach (batch) =>

      for event in batch.events
        event.version = batch.version
        eventClass = @_lookupClass event.type

        events.push new eventClass(event)

    return events

  _lookupClass: (identifier) ->
    namespace = @globalNamespace
    path = identifier.split '.'

    for segment in path
      namespace = namespace[segment]

    return namespace
