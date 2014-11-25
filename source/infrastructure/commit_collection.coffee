
class Space.cqrs.CommitCollection

  @toString: -> 'Space.cqrs.CommitCollection'

  Dependencies:
    mongo: 'Mongo'
    configuration: 'Space.cqrs.Configuration'

  _collection: null

  onDependenciesReady: ->

    if @configuration.useInMemoryCollections
      @_collection = new @mongo.Collection null
    else
      @_collection = new @mongo.Collection 'space_cqrs_commits'

    @_collection._ensureIndex { "sourceId": 1, "version": 1 }, unique: true

  findOne: -> @_collection.findOne.apply @_collection, arguments

  find: -> @_collection.find.apply @_collection, arguments

  insert: -> @_collection.insert.apply @_collection, arguments

  update: -> @_collection.update.apply @_collection, arguments
