
class Space.cqrs extends Space.Module

  @publish this, 'Space.cqrs'

  RequiredModules: ['Space.messaging']

  configure: ->
    super
    @injector.map('Space.cqrs.Configuration').asStaticValue()
    @injector.map('Space.cqrs.AggregateRepository').asSingleton()
    @injector.map('Space.cqrs.ProcessManagerRepository').asSingleton()
    @injector.map('Space.cqrs.CommitCollection').asSingleton()
    @injector.map('Space.cqrs.CommitStore').asSingleton()
    @injector.map('Space.cqrs.CommitPublisher').asSingleton()
