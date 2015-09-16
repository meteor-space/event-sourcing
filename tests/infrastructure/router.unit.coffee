# =========== SETUP ============= #

RouterTests = Space.namespace('RouterTests')

Space.messaging.define Space.messaging.Command, 'RouterTests', {
  Create: targetId: String
  DoSomething: targetId: String
}

Space.messaging.define Space.messaging.Event, 'RouterTests', {
  SomethingHappenedInOtherContext: correlationId: String
  Created: sourceId: String
  DidSomething: sourceId: String
}

class RouterTests.Aggregate extends Space.eventSourcing.Aggregate

  initialize: (createCommand) -> @handle createCommand

  @handle RouterTests.Create, (command) ->
    @record new RouterTests.Created sourceId: @getId()

  @handle RouterTests.DoSomething, (command) ->
    @record new RouterTests.DidSomething sourceId: @getId()

class RouterTests.Router extends Space.eventSourcing.Router
  Aggregate: RouterTests.Aggregate
  CreateWith: RouterTests.Create
  RouteCommands: [RouterTests.DoSomething]
  # Example of how integration events from other bounded contexts
  # can be mapped to commands of this context.
  @mapEvent RouterTests.SomethingHappenedInOtherContext, (event) ->
    # The returned command will be routed to the aggregate
    return new RouterTests.DoSomething targetId: event.correlationId

class RouterTests.App extends Space.Application
  RequiredModules: ['Space.eventSourcing']
  Singletons: ['RouterTests.Router']
  Dependencies: {
    eventSourcingConfig: 'Space.eventSourcing.Configuration'
  }
  configure: -> @eventSourcingConfig.useInMemoryCollections = true

# ============= TESTS =============== #

describe 'Space.eventSourcing.Router', ->

  beforeEach ->
    @app = new RouterTests.App()
    @eventBus = @app.injector.get 'Space.messaging.EventBus'
    @commandBus = @app.injector.get 'Space.messaging.CommandBus'
    @aggregateId = '123'
    @eventSpy = sinon.spy()
    @app.start()
    # Create the aggregate
    @commandBus.send new RouterTests.Create targetId: @aggregateId

  it 'routes specificed commands to the aggregate', ->
    @eventBus.subscribeTo RouterTests.DidSomething, @eventSpy
    @commandBus.send new RouterTests.DoSomething targetId: @aggregateId
    expect(@eventSpy).to.have.been.called

  it 'allows to map integration events to commands', ->
    @eventBus.subscribeTo RouterTests.DidSomething, @eventSpy
    integrationEvent = new RouterTests.SomethingHappenedInOtherContext {
      correlationId: @aggregateId
    }
    @eventBus.publish integrationEvent
    expect(@eventSpy).to.have.been.called

  it 'throws good error message if aggregate is not specified', ->
    RouterTests.Router::Aggregate = null
    expect(=> new RouterTests.Router()).to.throw RouterTests.Router.ERRORS.aggregateNotSpecified
    RouterTests.Router::Aggregate = RouterTests.Aggregate

  it 'throws good error message if creation command is not specified', ->
    RouterTests.Router::CreateWith = null
    expect(=> new RouterTests.Router()).to.throw RouterTests.Router.ERRORS.missingCreateCommand
    RouterTests.Router::CreateWith = RouterTests.Create
