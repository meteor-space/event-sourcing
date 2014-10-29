
class Space.cqrs.Command

  @toString: -> 'Space.cqrs.Command'

  @type: (value) ->
    this::type = value
    @toString = -> value

  @ERRORS:
    typeRequiredError: "#{Command}: command type is required."

  type: null

  constructor: ->
    if not @type? then throw new Error Command.ERRORS.typeRequiredError