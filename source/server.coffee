
CommitsCollection = null

class Space.eventSourcing extends Space.Module

  @publish this, 'Space.eventSourcing'

  RequiredModules: ['Space.messaging']

  Dependencies: {
    mongo: 'Mongo'
  }

  Singletons: [
    'Space.eventSourcing.CommitPublisher'
  ]

  Configuration: {
    eventSourcing: {
      debug: false
    }
  }

  configure: ->
    if @Configuration.eventSourcing.commitsCollection?
      CommitsCollection = @Configuration.eventSourcing.commitsCollection
    else if !CommitsCollection?
      CommitsCollection = new @mongo.Collection 'space_cqrs_commits'
      CommitsCollection._ensureIndex { "sourceId": 1, "version": 1 }, unique: true

    @injector.map('Space.eventSourcing.Commits').to CommitsCollection
    @injector.map('Space.eventSourcing.Projector').asSingleton()
    @injector.map('Space.eventSourcing.Log').to =>
      console.log.apply(null, arguments) if @Configuration.eventSourcing.debug

  afterApplicationStart: ->
    @commitPublisher = @injector.get('Space.eventSourcing.CommitPublisher')
    @commitPublisher.startPublishing()

  reset: ->
    @injector.get('Space.eventSourcing.Commits').remove {}

  stop: ->
    @commitPublisher.stopPublishing()
