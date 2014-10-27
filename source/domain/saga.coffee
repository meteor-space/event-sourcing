
class Space.cqrs.Saga extends Space.cqrs.AggregateRoot

  @toString: -> 'Space.cqrs.Saga'

  _state: null
  _commands: null

  constructor: (id) ->
    super(id)
    @_commands = []

  addCommand: (command) -> @_commands.push command

  getCommands: -> @_commands

  hasState: (state) -> if state? then @_state == state else @_state?

  transitionTo: (@_state) ->