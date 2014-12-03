
class Space.cqrs extends Space.Module

  @publish this, 'Space.cqrs'

  configure: ->
    @injector.map(Space.cqrs.Configuration).asSingleton()
    @injector.map(Space.cqrs.CommandBus).asSingleton()