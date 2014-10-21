
class Space.cqrs extends Space.Module

  @publish this, 'Space.cqrs'

  configure: ->
    @injector.map(Space.cqrs.CommandBus).asSingleton()
    @injector.map(Space.cqrs.AggregateRepository).asSingleton()

    @injector.map(Space.cqrs.EventsCollection).asSingleton()
    @injector.map(Space.cqrs.EventBus).asSingleton()
    @injector.map(Space.cqrs.EventStore).asSingleton()