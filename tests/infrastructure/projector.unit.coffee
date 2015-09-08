
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

  class TestProjection extends Space.eventSourcing.Projection

    Dependencies:
      firstCollection: 'FirstCollection'
      secondCollection: 'SecondCollection'

    @on TestEvent, (event) ->
      record = {
        _id: event.sourceId
        value: event.value
        isFromReplay: true # This is the difference that would be "new"
      }
      @firstCollection.insert record
      @secondCollection.insert record

  class TestApp extends Space.Application

    RequiredModules: ['Space.eventSourcing']

    Dependencies: {
      eventSourcingConfig: 'Space.eventSourcing.Configuration'
    }

    configure: ->
      @injector.map('FirstCollection').to FirstCollection
      @injector.map('SecondCollection').to SecondCollection
      @injector.map('TestProjection').toSingleton TestProjection
      @eventSourcingConfig.useInMemoryCollections = true

    startup: -> @injector.create 'TestProjection'

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
      projector.replay {
        projections: ['FirstCollection', 'SecondCollection']
        rebuildOnly: ['FirstCollection']
      }

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
