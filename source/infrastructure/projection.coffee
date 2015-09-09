class Space.eventSourcing.Projection extends Space.messaging.Controller

  constructor: ->
    super
    if not @Collections?
      throw new Error 'Please define projection Collections<[String]> on the prototype.'
