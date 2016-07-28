Router = Space.eventSourcing.Router
Aggregate = Space.eventSourcing.Aggregate
Command = Space.domain.Command
Error = Space.Error
DomainException = Space.domain.Exception

# =========== TEST DATA ========== #

class MyInitializingCommand extends Command
  @type 'Space.eventSourcing.Router.MyInitializingCommand'

class MyAggregate extends Aggregate
  @type 'Space.eventSourcing.Router.MyAggregate'

class MyCommandInitializingRouter extends Router
  @type 'Space.eventSourcing.Router.MyRouter'
  eventSourceable: Space.eventSourcing.Router.MyAggregate
  initializingMessage:  Space.eventSourcing.Router.MyInitializingCommand

class InvalidState extends Error
  constructor:(commandName, currentState) ->
    Error.call(this, "Cannot #{commandName} when in #{currentState} state");

# ============== SPEC =============== #

describe "Space.eventSourcing.Router", ->

  beforeEach ->
    @id = new Guid();
    @message = new MyInitializingCommand({ targetId: @id })
    @router = new MyCommandInitializingRouter()
    @router.repository = { save: -> }
    @router.configuration = { appId: 'Space.eventSourcing.Router.Test' }
    @router.log = {
      warning: ->
      error: ->
    }
    @messageHandlerSpy = @router.messageHandler = sinon.spy()

  describe "Acknowledging success of message into the domain", ->

    it "invokes the callback with no arguments to acknowledge success of message", ->
      callback = sinon.spy()
      validStateChange = ->
      @router._nextStateOfEventSourceable(validStateChange, callback)
      expect(callback).to.have.been.calledWith()

    it "will skip the callback invocation if none supplied", ->
      newState = { 'prop1': 1 }
      validStateChange = -> newState
      nextState = @router._nextStateOfEventSourceable(validStateChange)
      expect(nextState).to.equal(newState)

  describe "Handling domain exceptions", ->

    it "interprets Space.Errors as domain exceptions, publishing an event on the server-side eventBus and invoking the callback with the error as the only argument", ->
      callback = sinon.spy()
      error = new InvalidState('PerformMyCommand', 'TheCurrentState')
      invalidStateChangeAttempt = -> throw error
      domainExceptionEvent = new DomainException({
        thrower: @router.eventSourceable.toString()
        error: error
      })
      publishSpy = @router.publish = sinon.spy()
      @router._nextStateOfEventSourceable(invalidStateChangeAttempt, callback)
      expect(publishSpy).to.have.been.calledWith(domainExceptionEvent)
      expect(callback).to.have.been.calledWith(error)

  describe "Handling concurrency exceptions", ->
    it "passes the message back to the handler if there's a concurrency exception when saving to the repository", ->
      error = new Space.eventSourcing.CommitConcurrencyException(@message.targetId, 1, 2)
      @router._handleSaveErrors(error, @message, @id)
      expect(@messageHandlerSpy).to.have.been.calledWith(@message)

    it "non-concurrency exception are re-thrown", ->
      error = new Error 'Some other exception'
      nonConcurrencyError = =>
        @router._handleSaveErrors(error, @message, @id)

      expect(nonConcurrencyError).to.throw(error)
