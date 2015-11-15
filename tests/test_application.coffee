'''
This test application is a simple event sourcing example that can be used
by integration tests to work in a real-world setup. The app can be configured
via the new configuration api introduced in space:base.
'''

class @CustomerApp extends Space.Application

  @publish this, 'CustomerApp'

  requiredModules: ['Space.eventSourcing']

  dependencies: {
    mongo: 'Mongo'
  }

  configuration: {
    appId: 'CustomerApp'
    eventSourcing: {
      snapshotting: {
        frequency: 2
      }
    }
  }

  Routers: [
    'CustomerApp.CustomerRegistrationRouter'
    'CustomerApp.CustomerRouter'
    'CustomerApp.EmailRouter'
  ]

  Projections: [
    'CustomerApp.CustomerRegistrationProjection'
  ]

  afterInitialize: ->
    @injector.map('CustomerApp.CustomerRegistrations').to new @mongo.Collection(null)

  onReset: ->
    @injector.get('CustomerApp.CustomerRegistrations').remove {}

# -------------- COMMANDS ---------------

Space.messaging.define Space.messaging.Command, 'CustomerApp', {
  RegisterCustomer: { customerId: String, customerName: String }
  CreateCustomer: { name: String }
  HandleNewCustomer: { customerId: String }
  SendWelcomeEmail: { customerId: String, customerName: String }
  MarkRegistrationAsComplete: {}
}

# --------------- EVENTS ---------------

Space.messaging.define Space.messaging.Event, 'CustomerApp', {
  RegistrationInitiated: { customerId: String, customerName: String }
  CustomerCreated: { customerName: String }
  WelcomeEmailTriggered: { customerId: String }
  WelcomeEmailSent: { email: String, customerId: String }
  RegistrationCompleted: {}
}

# -------------- AGGREGATES ---------------

class CustomerApp.Customer extends Space.eventSourcing.Aggregate

  fields: {
    name: String
  }

  commandMap: -> {
    'CustomerApp.CreateCustomer': (command) ->
      @record new CustomerApp.CustomerCreated {
        sourceId: @getId()
        customerName: command.name
      }
  }

  eventMap: -> {
    'CustomerApp.CustomerCreated': (event) -> @name = event.customerName
  }

CustomerApp.Customer.registerSnapshotType 'CustomerApp.CustomerSnapshot'

# -------------- PROCESSES ---------------

class CustomerApp.CustomerRegistration extends Space.eventSourcing.Process

  fields: {
    customerId: String
    customerName: String
  }

  STATES: {
    creatingCustomer: 'creatingCustomer'
    sendingWelcomeEmail: 'sendingWelcomeEmail'
    completed: 'completed'
  }

  commandMap: -> {
    'CustomerApp.RegisterCustomer': @_registerCustomer
    'CustomerApp.HandleNewCustomer': @_handleNewCustomer
    'CustomerApp.MarkRegistrationAsComplete': @_markAsComplete
  }

  eventMap: -> {
    'CustomerApp.RegistrationInitiated': @_onRegistrationInitiated
    'CustomerApp.WelcomeEmailTriggered': -> @_state = @STATES.sendingWelcomeEmail
    'CustomerApp.RegistrationCompleted': -> @_state = @STATES.completed
  }

  _registerCustomer: (command) ->
    @trigger new CustomerApp.CreateCustomer {
      targetId: command.customerId
      name: command.customerName
    }
    @record new CustomerApp.RegistrationInitiated {
      sourceId: @getId()
      customerId: command.customerId
      customerName: command.customerName
    }

  _handleNewCustomer: (command) ->
    @trigger new CustomerApp.SendWelcomeEmail {
      targetId: @customerId
      customerId: command.customerId
      customerName: @customerName
    }
    @record new CustomerApp.WelcomeEmailTriggered {
      sourceId: @getId()
      customerId: @customerId
    }

  _markAsComplete: -> @record new CustomerApp.RegistrationCompleted sourceId: @getId()

  _onRegistrationInitiated: (event) ->
    { @customerId, @customerName } = event
    @_state = @STATES.creatingCustomer

CustomerApp.CustomerRegistration.registerSnapshotType 'CustomerApp.CustomerRegistrationSnapshot'

# -------------- ROUTERS --------------- #

class CustomerApp.CustomerRegistrationRouter extends Space.eventSourcing.Router

  dependencies: {
    registrations: 'CustomerApp.CustomerRegistrations'
  }

  aggregate: CustomerApp.CustomerRegistration

  initializingCommand: CustomerApp.RegisterCustomer

  routeCommands: [
    CustomerApp.HandleNewCustomer
    CustomerApp.MarkRegistrationAsComplete
  ]

  eventSubscriptions: -> [
    'CustomerApp.CustomerCreated': (event) ->
      @send new CustomerApp.HandleNewCustomer {
        targetId: @_findRegistrationIdByCustomerId event.sourceId
        customerId: event.sourceId
      }
    'CustomerApp.WelcomeEmailSent': (event) ->
      @send new CustomerApp.MarkRegistrationAsComplete {
        targetId: @_findRegistrationIdByCustomerId event.customerId
      }
  ]

  _findRegistrationIdByCustomerId: (customerId) ->
    @registrations.findOne(customerId: customerId)._id

class CustomerApp.CustomerRouter extends Space.eventSourcing.Router

  aggregate: CustomerApp.Customer
  initializingCommand: CustomerApp.CreateCustomer

class CustomerApp.EmailRouter extends Space.Object

  @type 'CustomerApp.EmailRouter'

  @mixin [
    Space.messaging.CommandHandling
    Space.messaging.EventPublishing
  ]

  commandHandlers: -> [
    'CustomerApp.SendWelcomeEmail': (command) ->
      # simulate sub-system sending emails
      @publish new CustomerApp.WelcomeEmailSent {
        sourceId: '999'
        version: 1
        customerId: command.customerId
        email: "Hello #{command.customerName}"
      }
  ]

# -------------- VIEW PROJECTIONS --------------- #

class CustomerApp.CustomerRegistrationProjection extends Space.eventSourcing.Projection

  dependencies: {
    registrations: 'CustomerApp.CustomerRegistrations'
  }

  eventSubscriptions: -> [
    'CustomerApp.RegistrationInitiated': (event) ->
      @registrations.insert {
        _id: event.sourceId
        customerId: event.customerId
        customerName: event.customerName
        isCompleted: false
      }
    'CustomerApp.RegistrationCompleted': (event) ->
      @registrations.update { _id: event.sourceId }, $set: isCompleted: true
  ]
