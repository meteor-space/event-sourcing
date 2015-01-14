
class Space.cqrs.ValueObject extends Space.cqrs.Serializable

  @toString: -> 'Space.cqrs.ValueObject'

  constructor: (data) ->
    super data
    Object.freeze this
