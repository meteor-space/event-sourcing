
class Space.cqrs.EventBus

  _handlers: null

  constructor: -> @_handlers = {}

  publish: (event) ->

    if @_handlers[event.type]?

      # publish asynchronously to avoid cascading changes
      Meteor.setTimeout (=>
        handler(event) for handler in @_handlers[event.type]
      ), 1

  subscribe: (eventType, handler) -> (@_handlers[eventType] ?= []).push handler

  @toString: -> 'Space.cqrs.EventBus'