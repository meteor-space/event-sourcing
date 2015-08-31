
class Space.cqrs.ProcessManager extends Space.cqrs.Aggregate

  _commands: null

  @toString: -> 'Space.cqrs.ProcessManager'

  constructor: (id, data) ->
    @_commands = []
    super

  trigger: (command) -> @_commands.push command

  getCommands: -> @_commands
