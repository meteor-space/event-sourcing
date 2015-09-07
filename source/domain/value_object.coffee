
class Space.eventSourcing.ValueObject extends Space.messaging.Serializable

  @toString: -> 'Space.eventSourcing.ValueObject'

  freeze: -> Object.freeze? this
