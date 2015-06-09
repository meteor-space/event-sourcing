
class Space.cqrs extends Space.Module

  @publish this, 'Space.cqrs'

  RequiredModules: ['Space.messaging']

  Dependencies:
    mongo: 'Mongo'

  startup: ->
    configuration = @injector.get 'Space.cqrs.Configuration'
    if configuration.useInMemoryCollections
      commits = new @mongo.Collection null
    else
      commits = new @mongo.Collection 'space_cqrs_commits'
      commits._ensureIndex { "sourceId": 1, "version": 1 }, unique: true
      
    @injector.map('Space.cqrs.Commits').to commits
