
class Space.cqrs.ValueObject extends Space.messaging.Serializable

  @toString: -> 'Space.cqrs.ValueObject'

  constructor: ->
    super
    Object.freeze? this
