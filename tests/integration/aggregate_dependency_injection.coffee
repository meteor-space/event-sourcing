Space.messaging.define(Space.messaging.Command, {
  MyFirstCommand: { value: Number }
  MySecondCommand: { value: Number }
});

Space.messaging.define(Space.messaging.Event, {
  MyFirstEvent: { value: Number }
  MySecondEvent: { value: Number }
});

describe "Space.eventSourcing.Aggregate - dependency injection", ->

  MyApi = Space.messaging.Api.extend('MyApi', {
    methods: ->
      return [{
        'MyFirstCommand': (_, command) ->
          @send(command)
        'MySecondCommand': (_, command) ->
          @send(command)
      }]
  });

  Space.eventSourcing.Aggregate.extend('MyAggregate', {
    dependencies: {
      myCommandDependency: 'MyCommandDependency'
      myEventDependency: 'MyEventDependency'
    }
    commandMap: -> {
      'MyFirstCommand': @_myFirstCommand
      'MySecondCommand': @_mySecondCommand
    }
    eventMap: -> {
      'MyFirstEvent': @_myEvent
    }
    _myFirstCommand: (command) ->
      @myCommandDependency(command)
      @record(new MyFirstEvent(@_eventPropsFromCommand(command)))
    _mySecondCommand: (command) ->
      @myCommandDependency(command)
    _myEvent: (event) ->
      @myEventDependency(event)
  })
  MyAggregate.registerSnapshotType('MyAggregateSnapshot')

  Space.eventSourcing.Router.extend('MyAggregateRouter', {
    eventSourceable: MyAggregate
    initializingMessage: MyFirstCommand
    routeCommands: [
      MySecondCommand
    ]
  })

  beforeEach ->
    @aggregateId = new Guid()
    @myFirstEvent = new MyFirstEvent
      sourceId: @aggregateId, value: 123, eventVersion: 1, version: 1
    @myFirstCommand = new MyFirstCommand
      targetId: @aggregateId, value: 123
    @MySecondCommand = new MySecondCommand
      targetId: @aggregateId, value: 123

    @MyCommandDependency = MyCommandDependency = sinon.spy()
    @MyEventDependency = MyEventDependency = sinon.spy()

    MyApp = Space.Application.define('MyApp', {
      requiredModules: ['Space.eventSourcing']
      singletons: ['MyApi', 'MyAggregateRouter']
      onInitialize: ->
        @injector.map('MyCommandDependency').asStaticValue(MyCommandDependency)
        @injector.map('MyEventDependency').asStaticValue(MyEventDependency)
    })

    @App = new MyApp

  it 'on aggregates created by initializing message', ->
    @App.send(@myFirstCommand)
    expect(@MyCommandDependency).to.have.been.calledWithExactly @myFirstCommand

  it 'on handled command by existing aggregate', ->
    @App.send(@myFirstCommand)
    @App.send(@MySecondCommand)
    expect(@MyCommandDependency).to.have.been.calledWithExactly @MySecondCommand