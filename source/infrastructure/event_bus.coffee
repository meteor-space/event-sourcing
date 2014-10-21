
class Space.cqrs.EventBus

  _handlers: null

  constructor: -> @_handlers = {}

  publish: (event) ->

    if @_handlers[event.type]?
      handler(event) for handler in @_handlers[event.type]

  subscribe: (eventType, handler) -> (@_handlers[eventType] ?= []).push handler

  @toString: -> 'Space.cqrs.EventBus'