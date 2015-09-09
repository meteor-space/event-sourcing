
Projector = Space.eventSourcing.Projector

describe 'Space.eventSourcing.Projector', ->

  FirstCollection = new Mongo.Collection 'space_eventsourcing_firstCollection'
  SecondCollection = new Mongo.Collection 'space_eventsourcing_secondCollection'

  class TestEvent extends Space.messaging.Event
    @type 'Space.eventSourcing.ProjectorTestEvent'
    @fields: {
      sourceId: String
      value: String
    }

  class FirstProjection extends Space.eventSourcing.Projection

    Dependencies: { firstCollection: 'FirstCollection' }
    Collections: ['FirstCollection']

    @on TestEvent, (event) ->
      @firstCollection.insert {
        _id: event.sourceId
        value: event.value
        isFromReplay: true # This is the difference that would be "new"
      }

  class SecondProjection extends Space.eventSourcing.Projection

    Dependencies: { secondCollection: 'SecondCollection' }
    Collections: ['SecondCollection']

    @on TestEvent, (event) ->
      @secondCollection.insert {
        _id: event.sourceId
        value: event.value
        isFromReplay: true # This is the difference that would be "new"
      }

  class TestApp extends Space.Application

    RequiredModules: ['Space.eventSourcing']

    Dependencies: {
      eventSourcingConfig: 'Space.eventSourcing.Configuration'
    }

    configure: ->
      @injector.map('FirstCollection').to FirstCollection
      @injector.map('SecondCollection').to SecondCollection
      @injector.map('FirstProjection').toSingleton FirstProjection
      @injector.map('SecondProjection').toSingleton SecondProjection
      @eventSourcingConfig.useInMemoryCollections = true

    startup: ->
      @injector.create 'FirstProjection'
      @injector.create 'SecondProjection'

  describe 'replaying events to migrate projections', ->

    beforeEach ->
      FirstCollection.remove {}
      SecondCollection.remove {}
      @event = new TestEvent sourceId: 'test123', value: 'test'
      @app = new TestApp()
      @app.start()

    it 'updates the collections with the new projection data', ->

      # Insert some "old" data that has been in the DB before the replay
      FirstCollection.insert _id: @event.sourceId, value: @event.value
      SecondCollection.insert _id: @event.sourceId, value: @event.value

      # Insert a fake commit from the past
      @app.injector.get('Space.eventSourcing.Commits').insert {
        sourceId: @event.sourceId
        version: 1
        changes: {
          events: [EJSON.stringify(@event)]
          commands: []
        }
        isPublished: true
        insertedAt: new Date()
      }

      projector = @app.injector.get 'Space.eventSourcing.Projector'
      projector.replay projections: ['FirstProjection']

      # It should have updated the first collection
      expect(FirstCollection.find().fetch()).toMatch [
        _id: @event.sourceId
        value: @event.value
        isFromReplay: true
      ]
      # But not the second one!
      expect(SecondCollection.find().fetch()).toMatch [
        _id: @event.sourceId
        value: @event.value
      ]
