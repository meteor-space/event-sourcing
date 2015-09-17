# =========== SETUP ============= #

RouterTests = Space.namespace('RouterTests')

Space.messaging.define Space.messaging.Command, 'RouterTests', {
  CreateTestAggregate: targetId: String
  DoSomething: targetId: String
}

Space.messaging.define Space.messaging.Event, 'RouterTests', {
  SomethingHappenedInOtherContext: correlationId: String
  TestAggregateCreated: sourceId: String
  DidSomething: sourceId: String
}

class RouterTests.TestAggregate extends Space.eventSourcing.Aggregate

  initialize: (createCommand) -> @handle createCommand

  @handle RouterTests.CreateTestAggregate, (command) ->
    @record new RouterTests.TestAggregateCreated sourceId: @getId()

  @handle RouterTests.DoSomething, (command) ->
    @record new RouterTests.DidSomething sourceId: @getId()

class RouterTests.TestRouter extends Space.eventSourcing.Router
  Aggregate: RouterTests.TestAggregate
  InitializingCommand: RouterTests.CreateTestAggregate
  RouteCommands: [RouterTests.DoSomething]
  # Example of how integration events from other bounded contexts
  # can be mapped to commands of this context.
  @mapEvent RouterTests.SomethingHappenedInOtherContext, (event) ->
    # The returned command will be routed to the aggregate
    return new RouterTests.DoSomething targetId: event.correlationId

class RouterTests.TestApp extends Space.Application
  RequiredModules: ['Space.eventSourcing']
  Singletons: ['RouterTests.TestRouter']
  Dependencies: {
    eventSourcingConfig: 'Space.eventSourcing.Configuration'
  }
  configure: -> @eventSourcingConfig.useInMemoryCollections = true

# ============= TESTS =============== #

describe 'Space.eventSourcing.Router', ->

  beforeEach ->
    @app = new RouterTests.TestApp()
    @eventBus = @app.injector.get 'Space.messaging.EventBus'
    @commandBus = @app.injector.get 'Space.messaging.CommandBus'
    @aggregateId = '123'
    @eventSpy = sinon.spy()
    @app.start()
    # Create the aggregate
    @commandBus.send new RouterTests.CreateTestAggregate targetId: @aggregateId

  it 'routes specified commands to the aggregate', ->
    @eventBus.subscribeTo RouterTests.DidSomething, @eventSpy
    @commandBus.send new RouterTests.DoSomething targetId: @aggregateId
    expect(@eventSpy).to.have.been.called

  it 'maps integration events to commands', ->
    @eventBus.subscribeTo RouterTests.DidSomething, @eventSpy
    integrationEvent = new RouterTests.SomethingHappenedInOtherContext {
      correlationId: @aggregateId
    }
    @eventBus.publish integrationEvent
    expect(@eventSpy).to.have.been.called

  it 'throws custom error if aggregate is not specified', ->
    RouterTests.TestRouter::Aggregate = null
    expect(=> new RouterTests.TestRouter()).to.throw RouterTests.TestRouter.ERRORS.aggregateNotSpecified
    RouterTests.TestRouter::Aggregate = RouterTests.TestAggregate

  it 'throws custom error if initializing command is not specified', ->
    RouterTests.TestRouter::InitializingCommand = null
    expect(=> new RouterTests.TestRouter()).to.throw RouterTests.TestRouter.ERRORS.missingInitializingCommand
    RouterTests.TestRouter::InitializingCommand = RouterTests.CreateTestAggregate
