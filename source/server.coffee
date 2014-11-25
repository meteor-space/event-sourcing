
class Space.cqrs extends Space.Module

  @publish this, 'Space.cqrs'

  configure: ->
    @injector.map(Space.cqrs.Configuration).asSingleton()
    @injector.map(Space.cqrs.CommandBus).asSingleton()
    @injector.map(Space.cqrs.AggregateRepository).asSingleton()
    @injector.map(Space.cqrs.SagaRepository).asSingleton()
    @injector.map(Space.cqrs.CommitCollection).asSingleton()
    @injector.map(Space.cqrs.EventBus).asSingleton()
    @injector.map(Space.cqrs.CommitStore).asSingleton()
    @injector.map(Space.cqrs.CommitPublisher).asSingleton()