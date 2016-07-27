Router = Space.eventSourcing.Router
Aggregate = Space.eventSourcing.Aggregate
Command = Space.domain.Command

# =========== TEST DATA ========== #

class MyInitializingCommand extends Command
  @type 'Space.eventSourcing.Router.MyInitializingCommand'

class MyAggregate extends Aggregate
  @type 'Space.eventSourcing.Router.MyAggregate'

class MyCommandInitializingRouter extends Router
  @type 'Space.eventSourcing.Router.MyRouter'
  eventSourceable: Space.eventSourcing.Router.MyAggregate
  initializingMessage:  Space.eventSourcing.Router.MyInitializingCommand

# ============== SPEC =============== #

describe "Space.eventSourcing.Router", ->

  beforeEach ->
    @id = new Guid();
    @message = new MyInitializingCommand({ targetId: @id })
    @router = new MyCommandInitializingRouter()
    @router.repository = { save: -> }
    @router.configuration = { appId: 'Space.eventSourcing.Router.Test' }
    @router.log = { warning: -> }
    @messageHandlerSpy = @router.messageHandler = sinon.spy()

  describe "handling concurrency exceptions", ->
    it "passes the message back to the handler if there's a concurrency exception when saving to the repository", ->
      error = new Space.eventSourcing.CommitConcurrencyException(@message.targetId, 1, 2)
      @router._handleSaveErrors(error, @message, @id)
      expect(@messageHandlerSpy).to.have.been.calledWith(@message)

    it "non-concurrency exception are re-thrown", ->
      error = new Error 'Some other exception'
      nonConcurrencyError = =>
        @router._handleSaveErrors(error, @message, @id)

      expect(nonConcurrencyError).to.throw(error)
