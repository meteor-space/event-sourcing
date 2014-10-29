
describe.server 'Space.cqrs', ->

  beforeEach -> @module = new Space.cqrs()

  it 'maps the command bus as singleton', ->
    expect(@module).toMap(Space.cqrs.CommandBus).asSingleton()

  it 'maps the aggregate repository as singleton', ->
    expect(@module).toMap(Space.cqrs.AggregateRepository).asSingleton()

  it 'maps the saga repository as singleton', ->
    expect(@module).toMap(Space.cqrs.SagaRepository).asSingleton()

  it 'maps the commit collection as singleton', ->
    expect(@module).toMap(Space.cqrs.CommitCollection).asSingleton()

  it 'maps the event bus as singleton', ->
    expect(@module).toMap(Space.cqrs.EventBus).asSingleton()

  it 'maps the commit store as singleton', ->
    expect(@module).toMap(Space.cqrs.CommitStore).asSingleton()

  it 'maps the commit publisher as singleton', ->
    expect(@module).toMap(Space.cqrs.CommitPublisher).asSingleton()