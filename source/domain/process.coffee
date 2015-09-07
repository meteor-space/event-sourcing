
class Space.eventSourcing.Process extends Space.eventSourcing.Aggregate

  _commands: null

  @toString: -> 'Space.eventSourcing.Process'

  constructor: (id, data) ->
    @_commands = []
    super

  trigger: (command) -> @_commands.push command

  getCommands: -> @_commands
