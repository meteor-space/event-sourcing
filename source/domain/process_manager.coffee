
class Space.eventSourcing.ProcessManager extends Space.eventSourcing.Aggregate

  _commands: null

  @toString: -> 'Space.eventSourcing.ProcessManager'

  constructor: (id, data) ->
    @_commands = []
    super

  trigger: (command) -> @_commands.push command

  getCommands: -> @_commands
