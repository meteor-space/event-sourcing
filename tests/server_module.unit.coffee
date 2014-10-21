
# HELPERS

expectSingletonMapping = (mappedClass) ->

  mapping = asSingleton: sinon.spy()

  @test.injector.map.withArgs(mappedClass).returns mapping
  @test.module.configure()

  expect(@test.injector.map).to.have.been.calledWith mappedClass
  expect(mapping.asSingleton).to.have.been.calledOnce

# SPECS

describe.server 'Space.cqrs', ->

  beforeEach ->

    # simulate injector api
    @test.mappingApi = asSingleton: ->
    @test.injector = map: sinon.stub().returns @test.mappingApi

    # create module with stub injector
    @test.module = new Space.cqrs()
    @test.module.injector = @test.injector

  it 'maps the event store as singleton', ->
    expectSingletonMapping.call this, Space.cqrs.CommandBus

  it 'maps the event store as singleton', ->
    expectSingletonMapping.call this, Space.cqrs.AggregateRepository

  it 'maps the events collection as singleton', ->
    expectSingletonMapping.call this, Space.cqrs.EventsCollection

  it 'maps the event store as singleton', ->
    expectSingletonMapping.call this, Space.cqrs.EventBus

  it 'maps the event store as singleton', ->
    expectSingletonMapping.call this, Space.cqrs.EventStore
