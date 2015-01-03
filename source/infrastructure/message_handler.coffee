
class Space.cqrs.MessageHandler

  Dependencies:
    eventBus: 'Space.cqrs.EventBus'
    commandBus: 'Space.cqrs.CommandBus'
    util: 'underscore'
    meteor: 'Meteor'

  @toString: -> 'Space.cqrs.MessageHandler'

  @ERRORS:
    unkownMessageType: "#{MessageHandler}: message type unknown: "

  onDependenciesReady: ->

    for type, eventHandler of @constructor._eventHandlers
      eventHandler = @util.bind(eventHandler, this)
      @eventBus.subscribe type, @meteor.bindEnvironment(eventHandler)

    for type, commandHandler of @constructor._commandHandlers
      commandHandler = @util.bind(commandHandler, this)
      @commandBus.registerHandler type, @meteor.bindEnvironment(commandHandler)

  @handle: (messageType, handler) ->

    unless @_eventHandlers? then @_eventHandlers = {}
    unless @_commandHandlers? then @_commandHandlers = {}

    classPath = messageType.toString()
    className = classPath.split('.').pop()

    this.prototype["handle#{className}"] = handler

    if messageType.__super__.constructor is Space.cqrs.Event
      @_eventHandlers[classPath] = handler

    else if messageType.__super__.constructor is Space.cqrs.Command
      @_commandHandlers[classPath] = handler

    else
      throw new Error @ERRORS.unkownMessageType + "<#{classPath}>"
