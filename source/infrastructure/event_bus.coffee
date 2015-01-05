
class Space.cqrs.EventBus

  _handlers: null

  constructor: -> @_handlers = {}

  publish: (event) ->

    if @_handlers[event.typeName()]?
      handler(event) for handler in @_handlers[event.typeName()]

  subscribe: (typeName, handler) -> (@_handlers[typeName] ?= []).push handler

  @toString: -> 'Space.cqrs.EventBus'
