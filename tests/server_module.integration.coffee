
# ============== INTEGRATION SETUP =============== #

class @CustomerApp extends Space.Application

  RequiredModules: ['Space.cqrs']

  Dependencies:
    commandBus: 'Space.cqrs.CommandBus'
    eventBus: 'Space.cqrs.EventBus'
    aggregateRepository: 'Space.cqrs.AggregateRepository'
    sagaRepository: 'Space.cqrs.SagaRepository'
    commits: 'Space.cqrs.CommitCollection'
    Mongo: 'Mongo'

  _greeting: 'Hello'
  _sagaCollection: null

  configure: ->
    @commandBus.registerHandler CustomerApp.RegisterCustomer, @_registerCustomer
    @commandBus.registerHandler CustomerApp.CreateCustomer, @_createCustomer
    @commandBus.registerHandler CustomerApp.SendWelcomeEmail, @_sendWelcomeEmail

    @eventBus.subscribe CustomerApp.RegistrationInitiated, @_createRegistration
    @eventBus.subscribe CustomerApp.CustomerCreated, @_handleCustomerCreated
    @eventBus.subscribe CustomerApp.WelcomeEmailSent, @_handleWelcomeEmailSent
    @eventBus.subscribe CustomerApp.RegistrationCompleted, @_handleRegistrationCompleted

    @_sagaCollection = new @Mongo.Collection null

  setGreeting: (greeting) -> @_greeting = greeting

  sendCommand: -> @commandBus.send.apply @commandBus, arguments

  subscribeTo: -> @eventBus.subscribe.apply @eventBus, arguments

  resetDatabase: -> @commits._collection.remove {}

  _createRegistration: (event) =>

    @_sagaCollection.insert {
      _id: event.sourceId
      customerId: event.data.customerId
      customerName: event.data.customerName
      isCompleted: false
    }

  _registerCustomer: (data) =>

    customerRegistration = new CustomerRegistration data.registrationId, data
    @sagaRepository.save customerRegistration

  _createCustomer: (data) =>

    customer = new Customer data.customerId, data
    @aggregateRepository.save customer

  _handleCustomerCreated: (event) =>

    registration = @_sagaCollection.findOne customerId: event.sourceId

    customerRegistration = @sagaRepository.find CustomerRegistration, registration._id
    customerRegistration.handleCustomerCreated event

    @sagaRepository.save customerRegistration

  _sendWelcomeEmail: (data) =>

    # simulate sub-system sending emails
    @eventBus.publish new CustomerApp.WelcomeEmailSent {
      sourceId: '999'
      version: 1
      data:
        customerId: data.customerId
        email: "#{@_greeting} #{data.customerName}"
    }

  _handleWelcomeEmailSent: (event) =>

    registration = @_sagaCollection.findOne customerId: event.data.customerId

    customerRegistration = @sagaRepository.find CustomerRegistration, registration._id
    customerRegistration.handleWelcomeEmailSent()

    @sagaRepository.save customerRegistration

  _handleRegistrationCompleted: (event) =>

    @_sagaCollection.update { _id: event.sourceId }, $set: isCompleted: true


# -------------- COMMANDS ---------------

class CustomerApp.RegisterCustomer extends Space.cqrs.Command

  @type 'CustomerApp.RegisterCustomer'
  constructor: (data) -> { @registrationId, @customerId, @version, @customerName } = data

class CustomerApp.CreateCustomer extends Space.cqrs.Command

  @type 'CustomerApp.CreateCustomer'
  constructor: (data) -> { @customerId, @version, @name } = data

class CustomerApp.SendWelcomeEmail extends Space.cqrs.Command

  @type 'CustomerApp.SendWelcomeEmail'
  constructor: (data) -> { @customerId, @version, @customerName } = data

# --------------- EVENTS ---------------

class CustomerApp.RegistrationInitiated extends Space.cqrs.Event

  @type 'CustomerApp.RegistrationInitiated'

class CustomerApp.CustomerCreated extends Space.cqrs.Event

  @type 'CustomerApp.CustomerCreated'

class CustomerApp.WelcomeEmailTriggered extends Space.cqrs.Event

  @type 'CustomerApp.WelcomeEmailTriggered'

class CustomerApp.WelcomeEmailSent extends Space.cqrs.Event

  @type 'CustomerApp.WelcomeEmailSent'

class CustomerApp.RegistrationCompleted extends Space.cqrs.Event

  @type 'CustomerApp.RegistrationCompleted'

# -------------- ENTITIES ---------------

class Customer extends Space.cqrs.AggregateRoot

  _name: null

  constructor: (id, data) ->

    super(id)

    @mapEvents CustomerApp.CustomerCreated, @_applyCustomerCreated

    if @isHistory data then @loadHistory data
    else
      # new customer
      @applyEvent new CustomerApp.CustomerCreated {
        sourceId: id
        data:
          name: data.name
      }

  _applyCustomerCreated: (event) -> @_name = event.data.name

# -------------- SAGAS ---------------

class CustomerRegistration extends Space.cqrs.Saga

  @STATES:
    creatingCustomer: 0
    sendingWelcomeEmail: 1
    completed: 2

  _customerId: null
  _customerName: null

  constructor: (id, data) ->

    super(id)

    @mapEvents(
      CustomerApp.RegistrationInitiated, @_initiate
      CustomerApp.WelcomeEmailTriggered, @_handleWelcomeEmailTriggered
      CustomerApp.RegistrationCompleted, @_complete
    )

    if @isHistory data then @loadHistory data
    else

      @addCommand new CustomerApp.CreateCustomer {
        customerId: data.customerId
        name: data.customerName
      }

      @applyEvent new CustomerApp.RegistrationInitiated {
        sourceId: id
        data:
          customerId: data.customerId
          customerName: data.customerName
      }

  handleCustomerCreated: (event) ->

    @addCommand new CustomerApp.SendWelcomeEmail {
      customerId: @_customerId
      customerName: @_customerName
    }

    @applyEvent new CustomerApp.WelcomeEmailTriggered {
      sourceId: @getId()
      data:
        customerId: @_customerId
    }

  handleWelcomeEmailSent: (event) ->
    @applyEvent new CustomerApp.RegistrationCompleted sourceId: @getId()

  _initiate: (event) ->
    @_customerId = event.data.customerId
    @_customerName = event.data.customerName
    @transitionTo CustomerRegistration.STATES.creatingCustomer

  _handleWelcomeEmailTriggered: ->
    @transitionTo CustomerRegistration.STATES.sendingWelcomeEmail

  _complete: -> @transitionTo CustomerRegistration.STATES.completed

# ============== INTEGRATION TESTING =============== #

describe.server 'Space.cqrs (integration)', ->

  # commands
  RegisterCustomer = CustomerApp.RegisterCustomer

  # events
  RegistrationInitiated = CustomerApp.RegistrationInitiated
  CustomerCreated = CustomerApp.CustomerCreated
  WelcomeEmailTriggered = CustomerApp.WelcomeEmailTriggered
  WelcomeEmailSent = CustomerApp.WelcomeEmailSent
  RegistrationCompleted = CustomerApp.RegistrationCompleted

  # fixtures
  customer = id: '123', name: 'Dominik'
  registration = id: '242'
  greeting = 'Welcome'

  beforeEach ->
    @app = new CustomerApp()
    @app.setGreeting greeting
    @app.resetDatabase()
    @app.run()

  it 'handles commands and publishes events correctly', (waitFor) ->

    registrationInitiatedSpy = sinon.spy()
    customerCreatedSpy = sinon.spy()
    welcomeEmailTriggeredSpy = sinon.spy()
    welcomeEmailSentSpy = sinon.spy()
    registrationCompletedSpy = sinon.spy()

    @app.subscribeTo RegistrationInitiated, registrationInitiatedSpy
    @app.subscribeTo CustomerCreated, customerCreatedSpy
    @app.subscribeTo WelcomeEmailTriggered, welcomeEmailTriggeredSpy
    @app.subscribeTo WelcomeEmailSent, welcomeEmailSentSpy
    @app.subscribeTo RegistrationCompleted, registrationCompletedSpy

    @app.sendCommand RegisterCustomer, new RegisterCustomer {
      registrationId: registration.id
      customerId: customer.id
      customerName: customer.name
    }

    testAsyncExpectations = ->

      expect(registrationInitiatedSpy).to.have.been.calledWithMatch new RegistrationInitiated {
        sourceId: registration.id
        version: 1
        data:
          customerId: customer.id
          customerName: customer.name
      }

      expect(customerCreatedSpy).to.have.been.calledWithMatch new CustomerCreated {
        sourceId: customer.id
        version: 1
        data:
          name: customer.name
      }

      expect(welcomeEmailTriggeredSpy).to.have.been.calledWithMatch new WelcomeEmailTriggered {
        sourceId: registration.id
        version: 2
        data:
          customerId: customer.id
      }

      expect(welcomeEmailSentSpy).to.have.been.calledWithMatch new WelcomeEmailSent {
        sourceId: '999'
        version: 1
        data:
          email: "#{greeting} #{customer.name}"
      }

      expect(registrationCompletedSpy).to.have.been.calledWithMatch new RegistrationCompleted {
        sourceId: registration.id
        version: 3
      }

    Meteor.setTimeout waitFor(testAsyncExpectations), 50
