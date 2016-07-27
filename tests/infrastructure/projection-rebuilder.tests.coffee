describe 'Space.eventSourcing.ProjectionRebuilder', ->

  FirstCollection = new Mongo.Collection 'space_eventsourcing_firstCollection'
  SecondCollection = new Mongo.Collection 'space_eventsourcing_secondCollection'

  class TestEvent extends Space.domain.Event
    @type 'Space.eventSourcing.RebuildTestEvent'
    @fields: {
      sourceId: String
      value: String
    }

  class FirstProjection extends Space.eventSourcing.Projection
    @type 'Space.eventSourcing.FirstTestProjection'
    collections: {
      firstCollection: 'FirstCollection'
    }

    eventSubscriptions: -> [
      'Space.eventSourcing.RebuildTestEvent': (event) ->
        @firstCollection.insert {
          _id: event.sourceId
          value: event.value
          isFromRebuild: true # This is the difference that would be "new"
        }
    ]

  class SecondProjection extends Space.eventSourcing.Projection
    @type 'Space.eventSourcing.SecondProjection'
    collections: {
      secondCollection: 'SecondCollection'
    }

    eventSubscriptions: -> [
      'Space.eventSourcing.RebuildTestEvent': (event) ->
        @secondCollection.insert {
          _id: event.sourceId
          value: event.value
          isFromRebuild: true # This is the difference that would be "new"
        }
    ]

  class TestApp extends Space.Application

    requiredModules: ['Space.eventSourcing']
    configuration: {
      appId: 'TestApp'
    }

    afterInitialize: ->
      @injector.map('FirstCollection').to FirstCollection
      @injector.map('SecondCollection').to SecondCollection
      @injector.map('FirstProjection').toSingleton FirstProjection
      @injector.map('SecondProjection').toSingleton SecondProjection

    afterStart: ->
      @injector.create 'FirstProjection'
      @injector.create 'SecondProjection'

  beforeEach ->
    FirstCollection.remove {}
    SecondCollection.remove {}
    @event = new TestEvent sourceId: 'test123', value: 'test'
    @app = new TestApp()
    @app.reset()

    # Insert some "old" data that has been in the DB before the replay
    FirstCollection.insert _id: @event.sourceId, value: @event.value
    SecondCollection.insert _id: @event.sourceId, value: @event.value

    # Insert a fake commit from the past
    @app.injector.get('Space.eventSourcing.Commits').insert {
      sourceId: @event.sourceId
      version: 1
      changes: {
        events: [type: @event.typeName(), data: @event.toData()]
        commands: []
      }
      insertedAt: new Date()
      eventTypes: [TestEvent]
      commandTypes: []
      sentBy: @app.configuration.appId
      receivers: [ appId: @app.configuration.appId, receivedAt: new Date()]
    }

    @app.start()

  afterEach ->
    @app.stop()

  it 'rebuilds the collections of nominated projections using historical events', ->

    rebuilder = @app.injector.get 'Space.eventSourcing.ProjectionRebuilder'
    rebuilder.rebuild ['FirstProjection']

    # It should have updated the first collection
    expect(FirstCollection.find().fetch()).toMatch [
      _id: @event.sourceId
      value: @event.value
      isFromRebuild: true
    ]
    # But not the second one!
    expect(SecondCollection.find().fetch()).toMatch [
      _id: @event.sourceId
      value: @event.value
    ]

  it 'rejects attempts to rebuild projections that are already being rebuilt', ->

    rebuilder = @app.injector.get 'Space.eventSourcing.ProjectionRebuilder'
    projection = @app.injector.get 'FirstProjection'
    projection.enterRebuildMode()
    try
      rebuilder.rebuild ['FirstProjection']
    catch error
      expect(error).to.be.instanceOf(Space.eventSourcing.ProjectionAlreadyRebuilding)

  it 'restores the real collection and returns the projection to the correct
    state if an exception occurs in the event replay', ->

    rebuilder = @app.injector.get 'Space.eventSourcing.ProjectionRebuilder'
    projection = @app.injector.get 'FirstProjection'
    collection = @app.injector.get 'FirstCollection'
    projection.on = -> throw new Error('Simulated error in replay')

    try
      rebuilder.rebuild ['FirstProjection']
    catch error
      expect(error).to.deep.equal(new Error 'Simulated error in replay')
    # Only persistent collections have a connection
    expect(collection._connection).to.not.equal(null);
    expect(projection._state).to.equal('projecting')
