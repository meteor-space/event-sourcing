
globalNamespace = this

class Space.cqrs.CommandBus

  @toString: -> 'Space.cqrs.CommandBus'

  Dependencies:
    meteor: 'Meteor'
    configuration: 'Space.cqrs.Configuration'

  _meteorMethod: 'space-cqrs-handle-command'
  _handlers: null

  onDependenciesReady: ->

    if !@meteor.isServer then return

    @_handlers = {}

    if @configuration.createMeteorMethods

      commandBusMethods = {}
      commandBusMethods[@_meteorMethod] = @_handleCommand

      @meteor.methods commandBusMethods

  send: (command, callback) ->

    if @meteor.isClient
      @meteor.call @_meteorMethod, command, callback
    else
      @_handleCommand command

  registerHandler: (typeName, handler) ->

    if @_handlers[typeName]?
      throw new Error "There is already an handler for #{typeName} commands."

    @_handlers[typeName] = handler

  _handleCommand: (command, data) =>

    handler = @_handlers[command.typeName()]

    if not handler?
      throw new @meteor.Error "Missing command handler for <#{command.typeName()}>."

    handler(command)
