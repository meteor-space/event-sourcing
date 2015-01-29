
class Space.cqrs.ProcessManager extends Space.cqrs.Aggregate

  _state: null
  _commands: null

  @toString: -> 'Space.cqrs.ProcessManager'

  constructor: (id, data) ->
    @_commands = []
    super(id, data)

  trigger: (command) -> @_commands.push command

  getCommands: -> @_commands

  hasState: (state) -> if state? then @_state == state else @_state?

  transitionTo: (@_state) ->

Space.cqrs.ProcessManager::handle = Space.cqrs.Aggregate::replay
