
class Space.cqrs.Saga extends Space.cqrs.Aggregate

  _state: null
  _commands: null

  @toString: -> 'Space.cqrs.Saga'

  constructor: (id, data) ->
    @_commands = []
    super(id, data)

  trigger: (command) -> @_commands.push command

  getCommands: -> @_commands

  hasState: (state) -> if state? then @_state == state else @_state?

  transitionTo: (@_state) ->