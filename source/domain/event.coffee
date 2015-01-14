
class Space.cqrs.Event extends Space.cqrs.Serializable

  @type 'Space.cqrs.Event', -> {
    sourceId: String
    data: Match.Optional(Object)
    version: Match.Optional(Match.Integer)
  }

  @ERRORS:
    paramsRequiredError: "#{Event}: params are required."
    sourceIdRequired: "#{Event}: sourceId is required."

  constructor: (params) ->

    if not params? then throw new Error Event.ERRORS.paramsRequiredError
    if not params.sourceId? then throw new Error Event.ERRORS.sourceIdRequired

    params.data ?= {}

    super params
