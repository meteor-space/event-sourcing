
class Space.cqrs.Event extends Space.cqrs.Serializable

  @type 'Space.cqrs.Event', ->
    sourceId: String
    data: Match.Optional(Object)
    version: Match.Optional(Match.Integer)
