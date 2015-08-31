
# ============== INTEGRATION SETUP =============== #
class @CustomerApp extends Space.Application

  RequiredModules: ['Space.cqrs']

  Dependencies:
    commandBus: 'Space.messaging.CommandBus'
    eventBus: 'Space.messaging.EventBus'
    configuration: 'Space.cqrs.Configuration'
    Mongo: 'Mongo'

  Singletons: [
    'CustomerApp.CustomerRegistrationRouter'
    'CustomerApp.CustomerRouter'
    'CustomerApp.EmailRouter'
    'CustomerApp.CustomerRegistrationViewModel'
  ]

  configure: ->
    @configuration.useInMemoryCollections = true
    collection = new @Mongo.Collection(null)
    @injector.map('CustomerApp.CustomerRegistrations').to collection

  startup: -> @resetDatabase()

  sendCommand: -> @commandBus.send.apply @commandBus, arguments

  subscribeTo: -> @eventBus.subscribeTo.apply @eventBus, arguments

  resetDatabase: ->
    @commits = @injector.get 'Space.cqrs.Commits'
    @commits.remove {}

# -------------- COMMANDS ---------------

Space.messaging.defineSerializables Space.messaging.Command, 'CustomerApp', {

  RegisterCustomer:
    registrationId: String
    customerId: String
    customerName: String

  CreateCustomer:
    customerId: String
    name: String

  SendWelcomeEmail:
    customerId: String
    customerName: String
}

# --------------- EVENTS ---------------

Space.messaging.defineSerializables Space.messaging.Event, 'CustomerApp', {

  RegistrationInitiated:
    sourceId: String
    version: Match.Optional(Match.Integer)
    customerId: String
    customerName: String

  CustomerCreated:
    sourceId: String
    version: Match.Optional(Match.Integer)
    customerName: String

  WelcomeEmailTriggered:
    sourceId: String
    version: Match.Optional(Match.Integer)
    customerId: String

  WelcomeEmailSent:
    sourceId: String
    version: Match.Optional(Match.Integer)
    customerId: String
    email: String

  RegistrationCompleted:
    sourceId: String
    version: Match.Optional(Match.Integer)
}

# -------------- AGGREGATES ---------------

class CustomerApp.Customer extends Space.cqrs.Aggregate

  _name: null

  initialize: (id, data) ->

    @record new CustomerApp.CustomerCreated
      sourceId: id
      customerName: data.name

  @handle CustomerApp.CustomerCreated, (event) -> @_name = event.customerName

# -------------- SAGAS ---------------

class CustomerApp.CustomerRegistration extends Space.cqrs.ProcessManager

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
    @_state = CustomerApp.CustomerRegistration.STATES.creatingCustomer

  @handle CustomerApp.WelcomeEmailTriggered, ->
    @_state = CustomerApp.CustomerRegistration.STATES.sendingWelcomeEmail

  @handle CustomerApp.RegistrationCompleted, ->
    @_state = CustomerApp.CustomerRegistration.STATES.completed

# -------------- ROUTERS --------------- #

class CustomerApp.CustomerRegistrationRouter extends Space.messaging.Controller

  Dependencies:
    repository: 'Space.cqrs.Repository'
    registrations: 'CustomerApp.CustomerRegistrations'

  @handle CustomerApp.RegisterCustomer, (command) ->
    registration = new CustomerApp.CustomerRegistration command.registrationId, command
    @repository.save registration

  @on CustomerApp.CustomerCreated, (event) ->
    registration = @_findRegistrationByCustomerId event.sourceId
    registration.onCustomerCreated event
    @repository.save registration

  @on CustomerApp.WelcomeEmailSent, (event) ->
    registration = @_findRegistrationByCustomerId event.customerId
    registration.onWelcomeEmailSent()
    @repository.save registration

  _findRegistrationByCustomerId: (customerId) ->
    registrationId = @registrations.findOne(customerId: customerId)._id
    return @repository.find CustomerApp.CustomerRegistration, registrationId


class CustomerApp.CustomerRouter extends Space.messaging.Controller

  @toString: -> 'CustomerApp.CustomerRouter'

  Dependencies:
    repository: 'Space.cqrs.Repository'

  @handle CustomerApp.CreateCustomer, (command) ->
    @repository.save new CustomerApp.Customer command.customerId, command


class CustomerApp.EmailRouter extends Space.messaging.Controller

  @toString: -> 'CustomerApp.EmailRouter'

  Dependencies:
    eventBus: 'Space.messaging.EventBus'

  @handle CustomerApp.SendWelcomeEmail, (command) ->

    # simulate sub-system sending emails
    @eventBus.publish new CustomerApp.WelcomeEmailSent
      sourceId: '999'
      version: 1
      customerId: command.customerId
      email: "Hello #{command.customerName}"

# -------------- VIEW MODELS --------------- #

class CustomerApp.CustomerRegistrationViewModel extends Space.messaging.Controller

  Dependencies:
    registrations: 'CustomerApp.CustomerRegistrations'

  @on CustomerApp.RegistrationInitiated, (event) ->

    @registrations.insert
      _id: event.sourceId
      customerId: event.customerId
      customerName: event.customerName
      isCompleted: false

  @on CustomerApp.RegistrationCompleted, (event) ->

    @registrations.update { _id: event.sourceId }, $set: isCompleted: true


# ============== INTEGRATION TESTING =============== #

describe.server 'Space.cqrs (integration)', ->

  # fixtures
  customer = id: 'customer_123', name: 'Dominik'
  registration = id: 'registration_123'

  beforeEach ->
    @app = new CustomerApp()
    @app.start()

  it 'handles commands and publishes events correctly', ->
    registrationInitiatedSpy = sinon.spy()
    customerCreatedSpy = sinon.spy()
    welcomeEmailTriggeredSpy = sinon.spy()
    welcomeEmailSentSpy = sinon.spy()
    registrationCompletedSpy = sinon.spy()

    @app.subscribeTo CustomerApp.RegistrationInitiated, registrationInitiatedSpy
    @app.subscribeTo CustomerApp.CustomerCreated, customerCreatedSpy
    @app.subscribeTo CustomerApp.WelcomeEmailTriggered, welcomeEmailTriggeredSpy
    @app.subscribeTo CustomerApp.WelcomeEmailSent, welcomeEmailSentSpy
    @app.subscribeTo CustomerApp.RegistrationCompleted, registrationCompletedSpy

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
