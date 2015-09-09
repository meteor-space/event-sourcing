class Space.eventSourcing.Projection extends Space.messaging.Controller

  Collections: {}

  constructor: ->
    super
    @Dependencies = {}
    _.extend @Dependencies, @constructor::Dependencies, @Collections
