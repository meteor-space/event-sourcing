
# ============== INTEGRATION SETUP =============== #

class CustomerApp extends Space.Application

  RequiredModules: ['Space.cqrs']

  Dependencies:
    eventBus: 'Space.cqrs.EventBus'
    configuration: 'Space.cqrs.Configuration'
    Mongo: 'Mongo'

  configure: ->

    @configuration.createMeteorMethods = false
    @configuration.useInMemoryCollections = true

    @commandBus = @injector.get 'Space.cqrs.CommandBus'
    @commits = @injector.get 'Space.cqrs.CommitCollection'

    @injector.map('CustomerRegistrations').toStaticValue new @Mongo.Collection(null)
    @injector.map(CustomerRegistrationRouter).asSingleton()
    @injector.map(CustomerRouter).asSingleton()
    @injector.map(EmailRouter).asSingleton()
    @injector.map(CustomerRegistrationViewModel).asSingleton()

  run: ->
    @injector.create CustomerRegistrationRouter
    @injector.create CustomerRouter
    @injector.create EmailRouter
    @injector.create CustomerRegistrationViewModel

  sendCommand: -> @commandBus.send.apply @commandBus, arguments

  subscribeTo: -> @eventBus.subscribe.apply @eventBus, arguments

  resetDatabase: -> @commits._collection.remove {}


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

# -------------- AGGREGATES ---------------

class Customer extends Space.cqrs.AggregateRoot

  _name: null

  initialize: (id, data) ->

    @record new CustomerApp.CustomerCreated {
      sourceId: id
      data:
        name: data.name
    }

  @handle CustomerApp.CustomerCreated, (event) -> @_name = event.data.name

# -------------- SAGAS ---------------

class CustomerRegistration extends Space.cqrs.Saga

  _customerId: null
  _customerName: null

  @STATES:
    creatingCustomer: 0
    sendingWelcomeEmail: 1
    completed: 2

  initialize: (id, data) ->

    @trigger new CustomerApp.CreateCustomer {
      customerId: data.customerId
      name: data.customerName
    }

    @record new CustomerApp.RegistrationInitiated {
      sourceId: id
      data:
        customerId: data.customerId
        customerName: data.customerName
    }

  onCustomerCreated: (event) ->

    @trigger new CustomerApp.SendWelcomeEmail {
      customerId: @_customerId
      customerName: @_customerName
    }

    @record new CustomerApp.WelcomeEmailTriggered {
      sourceId: @getId()
      data:
        customerId: @_customerId
    }

  onWelcomeEmailSent: (event) ->
    @record new CustomerApp.RegistrationCompleted sourceId: @getId()

  @handle CustomerApp.RegistrationInitiated, (event) ->
    @_customerId = event.data.customerId
    @_customerName = event.data.customerName
    @transitionTo CustomerRegistration.STATES.creatingCustomer

  @handle CustomerApp.WelcomeEmailTriggered, ->
    @transitionTo CustomerRegistration.STATES.sendingWelcomeEmail

  @handle CustomerApp.RegistrationCompleted, ->
    @transitionTo CustomerRegistration.STATES.completed


# -------------- ROUTERS --------------- #

class CustomerRegistrationRouter extends Space.cqrs.MessageHandler

  @toString: -> 'CustomerRegistrationRouter'

  Dependencies:
    repository: 'Space.cqrs.SagaRepository'
    registrations: 'CustomerRegistrations'

  @handle CustomerApp.RegisterCustomer, (data) ->

    customerRegistration = new CustomerRegistration data.registrationId, data
    @repository.save customerRegistration, customerRegistration.getVersion()

  @handle CustomerApp.CustomerCreated, (event) ->

    registration = @registrations.findOne customerId: event.sourceId
    customerRegistration = @repository.find CustomerRegistration, registration._id
    customerRegistration.onCustomerCreated event
    @repository.save customerRegistration, customerRegistration.getVersion()

  @handle CustomerApp.WelcomeEmailSent, (event) ->

    registration = @registrations.findOne customerId: event.data.customerId
    customerRegistration = @repository.find CustomerRegistration, registration._id
    customerRegistration.onWelcomeEmailSent()
    @repository.save customerRegistration, customerRegistration.getVersion()


class CustomerRouter extends Space.cqrs.MessageHandler

  @toString: -> 'CustomerRouter'

  Dependencies:
    repository: 'Space.cqrs.AggregateRepository'

  @handle CustomerApp.CreateCustomer, (data) ->

    customer = new Customer data.customerId, data
    @repository.save customer, customer.getVersion()

class EmailRouter extends Space.cqrs.MessageHandler

  @toString: -> 'EmailRouter'

  Dependencies:
    eventBus: 'Space.cqrs.EventBus'

  @handle CustomerApp.SendWelcomeEmail, (data) ->

    # simulate sub-system sending emails
    @eventBus.publish new CustomerApp.WelcomeEmailSent {
      sourceId: '999'
      version: 1
      data:
        customerId: data.customerId
        email: "Hello #{data.customerName}"
    }

# -------------- VIEW MODELS --------------- #

class CustomerRegistrationViewModel extends Space.cqrs.MessageHandler

  @toString: -> 'CustomerRegistrationViewModel'

  Dependencies:
    registrations: 'CustomerRegistrations'

  @handle CustomerApp.RegistrationInitiated, (event) ->

    @registrations.insert {
      _id: event.sourceId
      customerId: event.data.customerId
      customerName: event.data.customerName
      isCompleted: false
    }

  @handle CustomerApp.RegistrationCompleted, (event) ->

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

    @app.subscribeTo CustomerApp.RegistrationInitiated, registrationInitiatedSpy
    @app.subscribeTo CustomerApp.CustomerCreated, customerCreatedSpy
    @app.subscribeTo CustomerApp.WelcomeEmailTriggered, welcomeEmailTriggeredSpy
    @app.subscribeTo CustomerApp.WelcomeEmailSent, welcomeEmailSentSpy
    @app.subscribeTo CustomerApp.RegistrationCompleted, registrationCompletedSpy

    @app.sendCommand new CustomerApp.RegisterCustomer {
      registrationId: registration.id
      customerId: customer.id
      customerName: customer.name
    }

    expect(registrationInitiatedSpy).to.have.been.calledWithMatch new CustomerApp.RegistrationInitiated {
      sourceId: registration.id
      version: 1
      data:
        customerId: customer.id
        customerName: customer.name
    }

    expect(customerCreatedSpy).to.have.been.calledWithMatch new CustomerApp.CustomerCreated {
      sourceId: customer.id
      version: 1
      data:
        name: customer.name
    }

    expect(welcomeEmailTriggeredSpy).to.have.been.calledWithMatch new CustomerApp.WelcomeEmailTriggered {
      sourceId: registration.id
      version: 2
      data:
        customerId: customer.id
    }

    expect(welcomeEmailSentSpy).to.have.been.calledWithMatch new CustomerApp.WelcomeEmailSent {
      sourceId: '999'
      version: 1
      data:
        email: "Hello #{customer.name}"
    }

    expect(registrationCompletedSpy).to.have.been.calledWithMatch new CustomerApp.RegistrationCompleted {
      sourceId: registration.id
      version: 3
    }
