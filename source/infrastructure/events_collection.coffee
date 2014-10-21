
class Space.cqrs.EventsCollection

  @toString: -> 'Space.cqrs.EventsCollection'

  Dependencies:
    mongo: 'Mongo'

  _collection: null

  onDependenciesReady: ->

    @_collection = new @mongo.Collection 'space_cqrs_events'
    @_collection._ensureIndex { "aggregateId": 1, "version": 1 }, unique: true

  findOne: -> @_collection.findOne.apply @_collection, arguments

  find: -> @_collection.find.apply @_collection, arguments

  insert: -> @_collection.insert.apply @_collection, arguments
