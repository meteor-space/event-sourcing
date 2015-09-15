
describe 'Space.eventSourcing.Router', ->

  class CreateCommand extends Space.messaging.Command
    @toString: -> 'Create'
    typeName: -> 'Create'
    @fields: targetId: String

  class IntegrationEvent extends Space.messaging.Event
    @toString: -> 'IntegrationEvent'
    typeName: -> 'IntegrationEvent'
    @fields: correlationId: String

  class IntegrationCommand extends Space.messaging.Command
    @toString: -> 'IntegrationCommand'
    typeName: -> 'IntegrationCommand'
    @fields: targetId: String

  beforeEach ->
    @createCommandSpy = createSpy = sinon.spy()
    @integrationCommandSpy = integrationSpy = sinon.spy()
    @fakeRepository = {
      find: sinon.stub()
      save: sinon.stub()
    }

    class TestAggregate extends Space.eventSourcing.Aggregate
      initialize: (createCommand) -> @handle createCommand
      @handle CreateCommand, createSpy
      @handle IntegrationCommand, integrationSpy

    class TestRouter extends Space.eventSourcing.Router
      Aggregate: TestAggregate
      CreateWith: CreateCommand
      RouteCommands: [IntegrationCommand]
      @mapEvent IntegrationEvent, (event) -> new IntegrationCommand {
        targetId: event.correlationId
      }

    @router = new TestRouter {
      eventBus: new Space.messaging.EventBus()
      commandBus: new Space.messaging.CommandBus()
      meteor: Meteor
      underscore: _
      repository: @fakeRepository
    }
    @router.onDependenciesReady()
    @TestAggregate = TestAggregate
    @TestRouter = TestRouter
    @aggregateId = '123'
    @aggregate = new TestAggregate new CreateCommand(targetId: @aggregateId)
    @fakeRepository.find.withArgs(TestAggregate, @aggregateId).returns @aggregate

  it 'routes creation commands to new instances of the specified aggregate', ->
    createCommand = new CreateCommand targetId: '123'
    @router.commandBus.send createCommand
    expect(@createCommandSpy).to.have.been.calledWithExactly createCommand

  it 'routes specificed commands to aggregates found by the repository', ->
    integrationCommand = new IntegrationCommand(targetId: @aggregateId)
    @router.commandBus.send integrationCommand
    expect(@integrationCommandSpy).to.have.been.calledWithExactly integrationCommand

  it 'allows to map integration events to commands', ->
    integrationEvent = new IntegrationEvent correlationId: @aggregateId
    @router.eventBus.publish integrationEvent
    expect(@integrationCommandSpy).to.have.been.calledWithMatch new IntegrationCommand {
      targetId: @aggregateId
    }

  it 'throws good error message if aggregate is not specified', ->
    @TestRouter::Aggregate = null
    expect(=> new @TestRouter()).to.throw @TestRouter.ERRORS.aggregateNotSpecified

  it 'throws good error message if creation command is not specified', ->
    @TestRouter::CreateWith = null
    expect(=> new @TestRouter()).to.throw @TestRouter.ERRORS.createCommandMissing
