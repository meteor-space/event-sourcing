# =========== TEST DATA ========== #

class MyInitializingCommand extends Space.domain.Command
  @type 'Space.eventSourcing.Router.MyInitializingCommand'

class MyAggregate extends Space.eventSourcing.Aggregate
  @type 'Space.eventSourcing.Router.MyAggregate'

class MyCommandInitializingRouter extends Space.eventSourcing.Router
  @type 'Space.eventSourcing.Router.MyRouter'
  eventSourceable: Space.eventSourcing.Router.MyAggregate
  initializingMessage:  Space.eventSourcing.Router.MyInitializingCommand

# ============== SPEC =============== #

describe "Space.eventSourcing.Router", ->

  beforeEach ->
    @id = new Guid();
    @message = new MyInitializingCommand({ targetId: @id })
    @router = new MyCommandInitializingRouter()
    @router.repository = {
      save: ->
      find: -> {}
    }
    @router.configuration = { appId: 'Space.eventSourcing.Router.Test' }
    @router.log = {
      debug: ->
      warning: ->
      error: ->
    }
    @router.publish = () ->
    @routeMessageSpy = @router._routeMessage = sinon.spy()

  describe "Handling concurrency exceptions", ->
    it "passes the message back to the handler if there's a concurrency exception when saving to the repository", ->
      error = new Space.eventSourcing.CommitConcurrencyException(@message.targetId, 1, 2)
      @router._handleSaveError(error, @message, @id)
      expect(@routeMessageSpy).to.have.been.called

    it "non-concurrency domain exceptions are returned in a callback", ->
      error = new Space.Error 'Some other exception'
      callback = sinon.spy()
      @router._handleRoutingErrors(error, @message, @id, callback)
      expect(callback).to.have.been.calledWithExactly(error)

    it "other errors are re-thrown", ->
      error = new Error()
      nonConcurrencyError = =>
        @router._handleRoutingErrors(error, @message, @id)
      expect(nonConcurrencyError).to.throw(error)
