
# ============== INTEGRATION SETUP =============== #
class CustomerApp extends Space.Application

  RequiredModules: ['Space.cqrs']

  Dependencies:
    commandBus: 'Space.messaging.CommandBus'
    eventBus: 'Space.messaging.EventBus'
    configuration: 'Space.cqrs.Configuration'
    Mongo: 'Mongo'

  configure: ->
    super
    @configuration.useInMemoryCollections = true
    @commits = @injector.get 'Space.cqrs.CommitCollection'
    @commits.remove {}
    @injector.map('CustomerRegistrations').to new @Mongo.Collection(null)
    @injector.map(CustomerRegistrationRouter).asSingleton()
    @injector.map(CustomerRouter).asSingleton()
    @injector.map(EmailRouter).asSingleton()
    @injector.map(CustomerRegistrationViewModel).asSingleton()

  run: ->
    super
    @injector.create CustomerRegistrationRouter
    @injector.create CustomerRouter
    @injector.create EmailRouter
    @injector.create CustomerRegistrationViewModel

  sendCommand: -> @commandBus.send.apply @commandBus, arguments

  subscribeTo: -> @eventBus.subscribeTo.apply @eventBus, arguments

  resetDatabase: -> @commits._collection.remove {}

# -------------- COMMANDS ---------------

class CustomerApp.RegisterCustomer extends Space.messaging.Command
  @type 'CustomerApp.RegisterCustomer'
  constructor: (data) ->
    { @registrationId, @customerId, @version, @customerName } = data

class CustomerApp.CreateCustomer extends Space.messaging.Command
  @type 'CustomerApp.CreateCustomer'
  constructor: (data) -> { @customerId, @version, @name } = data

class CustomerApp.SendWelcomeEmail extends Space.messaging.Command
  @type 'CustomerApp.SendWelcomeEmail'
  constructor: (data) -> { @customerId, @version, @customerName } = data

# --------------- EVENTS ---------------

class CustomerApp.RegistrationInitiated extends Space.messaging.Event
  @type 'CustomerApp.RegistrationInitiated'
  @fields:
    sourceId: String
    version: Match.Optional(Match.Integer)
    customerId: String
    customerName: String

class CustomerApp.CustomerCreated extends Space.messaging.Event
  @type 'CustomerApp.CustomerCreated'
  @fields:
    sourceId: String
    version: Match.Optional(Match.Integer)
    customerName: String

class CustomerApp.WelcomeEmailTriggered extends Space.messaging.Event
  @type 'CustomerApp.WelcomeEmailTriggered'
  @fields:
    sourceId: String
    version: Match.Optional(Match.Integer)
    customerId: String

class CustomerApp.WelcomeEmailSent extends Space.messaging.Event
  @type 'CustomerApp.WelcomeEmailSent'
  @fields:
    sourceId: String
    version: Match.Optional(Match.Integer)
    customerId: String
    email: String

class CustomerApp.RegistrationCompleted extends Space.messaging.Event
  @type 'CustomerApp.RegistrationCompleted'

# -------------- AGGREGATES ---------------

class Customer extends Space.cqrs.Aggregate

  _name: null

  initialize: (id, data) ->

    @record new CustomerApp.CustomerCreated
      sourceId: id
      customerName: data.name

  @handle CustomerApp.CustomerCreated, (event) -> @_name = event.customerName

# -------------- SAGAS ---------------

class CustomerRegistration extends Space.cqrs.ProcessManager

  _customerId: null
  _customerName: null

  @STATES:
    creatingCustomer: 0
    sendingWelcomeEmail: 1
    completed: 2

  initialize: (id, data) ->

    @trigger new CustomerApp.CreateCustomer
      customerId: data.customerId
      name: data.customerName

    @record new CustomerApp.RegistrationInitiated
      sourceId: id
      customerId: data.customerId
      customerName: data.customerName

  onCustomerCreated: (event) ->

    @trigger new CustomerApp.SendWelcomeEmail
      customerId: @_customerId
      customerName: @_customerName

    @record new CustomerApp.WelcomeEmailTriggered
      sourceId: @getId()
      customerId: @_customerId

  onWelcomeEmailSent: (event) ->
    @record new CustomerApp.RegistrationCompleted sourceId: @getId()

  @handle CustomerApp.RegistrationInitiated, (event) ->
    @_customerId = event.customerId
    @_customerName = event.customerName
    @transitionTo CustomerRegistration.STATES.creatingCustomer

  @handle CustomerApp.WelcomeEmailTriggered, ->
    @transitionTo CustomerRegistration.STATES.sendingWelcomeEmail

  @handle CustomerApp.RegistrationCompleted, ->
    @transitionTo CustomerRegistration.STATES.completed


# -------------- ROUTERS --------------- #

class CustomerRegistrationRouter extends Space.messaging.Controller

  @toString: -> 'CustomerRegistrationRouter'

  Dependencies:
    repository: 'Space.cqrs.Repository'
    registrations: 'CustomerRegistrations'

  @handle CustomerApp.RegisterCustomer, on: (event) ->

    registration = new CustomerRegistration event.registrationId, event
    @repository.save registration, registration.getVersion()

  @handle CustomerApp.CustomerCreated, on: (event) ->

    registrationId = @registrations.findOne(customerId: event.sourceId)._id
    registration = @repository.find CustomerRegistration, registrationId
    registration.onCustomerCreated event
    @repository.save registration, registration.getVersion()

  @handle CustomerApp.WelcomeEmailSent, on: (event) ->

    registrationId = @registrations.findOne(customerId: event.customerId)._id
    registration = @repository.find CustomerRegistration, registrationId
    registration.onWelcomeEmailSent()
    @repository.save registration, registration.getVersion()


class CustomerRouter extends Space.messaging.Controller

  @toString: -> 'CustomerRouter'

  Dependencies:
    repository: 'Space.cqrs.Repository'

  @handle CustomerApp.CreateCustomer, on: (command) ->

    customer = new Customer command.customerId, command
    @repository.save customer, customer.getVersion()

class EmailRouter extends Space.messaging.Controller

  @toString: -> 'EmailRouter'

  Dependencies:
    eventBus: 'Space.messaging.EventBus'

  @handle CustomerApp.SendWelcomeEmail, on: (command) ->

    # simulate sub-system sending emails
    @eventBus.publish new CustomerApp.WelcomeEmailSent
      sourceId: '999'
      version: 1
      customerId: command.customerId
      email: "Hello #{command.customerName}"

# -------------- VIEW MODELS --------------- #

class CustomerRegistrationViewModel extends Space.messaging.Controller

  @toString: -> 'CustomerRegistrationViewModel'

  Dependencies:
    registrations: 'CustomerRegistrations'

  @handle CustomerApp.RegistrationInitiated, on: (event) ->

    @registrations.insert
      _id: event.sourceId
      customerId: event.customerId
      customerName: event.customerName
      isCompleted: false

  @handle CustomerApp.RegistrationCompleted, on: (event) ->

    @registrations.update { _id: event.sourceId }, $set: isCompleted: true


# ============== INTEGRATION TESTING =============== #

describe.server 'Space.cqrs (integration)', ->

  # fixtures
  customer = id: 'customer_123', name: 'Dominik'
  registration = id: 'registration_123'

  beforeEach ->
    @app = new CustomerApp()
    @app.resetDatabase()
    @app.run()

  it 'handles commands and publishes events correctly', ->
    registrationInitiatedSpy = sinon.spy()
    customerCreatedSpy = sinon.spy()
    welcomeEmailTriggeredSpy = sinon.spy()
    welcomeEmailSentSpy = sinon.spy()
    registrationCompletedSpy = sinon.spy()

    @app.subscribeTo CustomerApp.RegistrationInitiated, on: registrationInitiatedSpy
    @app.subscribeTo CustomerApp.CustomerCreated, on: customerCreatedSpy
    @app.subscribeTo CustomerApp.WelcomeEmailTriggered, on: welcomeEmailTriggeredSpy
    @app.subscribeTo CustomerApp.WelcomeEmailSent, on: welcomeEmailSentSpy
    @app.subscribeTo CustomerApp.RegistrationCompleted, on: registrationCompletedSpy

    @app.sendCommand new CustomerApp.RegisterCustomer
      registrationId: registration.id
      customerId: customer.id
      customerName: customer.name

    expect(registrationInitiatedSpy).to.have.been.calledWithMatch(
      new CustomerApp.RegistrationInitiated
        sourceId: registration.id
        version: 1
        customerId: customer.id
        customerName: customer.name
    )

    expect(customerCreatedSpy).to.have.been.calledWithMatch(
      new CustomerApp.CustomerCreated
        sourceId: customer.id
        version: 1
        customerName: customer.name
    )

    expect(welcomeEmailTriggeredSpy).to.have.been.calledWithMatch(
      new CustomerApp.WelcomeEmailTriggered
        sourceId: registration.id
        version: 2
        customerId: customer.id
    )

    expect(welcomeEmailSentSpy).to.have.been.calledWithMatch(
      new CustomerApp.WelcomeEmailSent
        sourceId: '999'
        version: 1
        email: "Hello #{customer.name}"
        customerId: customer.id
    )

    expect(registrationCompletedSpy).to.have.been.calledWithMatch(
      new CustomerApp.RegistrationCompleted
        sourceId: registration.id
        version: 3
    )
