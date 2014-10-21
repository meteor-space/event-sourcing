
globalNamespace = this

class Space.cqrs.CommandBus

  Dependencies:
    meteor: 'Meteor'

  _meteorMethod: 'space-cqrs-handle-command'
  _handlers: null

  onDependenciesReady: ->

    if @meteor.isServer

      @_handlers = {}

      commandBusMethods = {}
      commandBusMethods[@_meteorMethod] = @_handleCommand

      @meteor.methods commandBusMethods

  send: (CommandClass, data, callback) ->

    if @meteor.isClient
      command = new CommandClass data
      @meteor.call @_meteorMethod, CommandClass.toString(), command, callback
    else
      @_handleCommand CommandClass.toString(), data

  registerHandler: (CommandClass, handler) ->

    if @_handlers[CommandClass]?
      throw new Error "There is already an handler for #{CommandClass} commands."

    @_handlers[CommandClass] = handler

  _handleCommand: (identifier, data) =>

    handler = @_handlers[identifier]

    if handler?
      commandClass = @_lookupClass(identifier)
      command = new commandClass(data)
      handler(command)
    else
      throw new @meteor.Error "Missing command handler for <#{identifier}>."

  _lookupClass: (identifier) ->
    namespace = globalNamespace
    path = identifier.split '.'

    for segment in path
      namespace = namespace[segment]

    return namespace

  @toString: -> 'Space.cqrs.CommandBus'