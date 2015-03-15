
class Space.cqrs.ValueObject extends Space.messaging.Serializable

  @toString: -> 'Space.cqrs.ValueObject'

  freeze: -> Object.freeze? this
