'''
This test application is a simple event sourcing example that can be used
by integration tests to work in a real-world setup. The app can be configured
via the new configuration api introduced in space:base.
'''

class @CustomerApp extends Space.Application

  RequiredModules: ['Space.eventSourcing']

  Dependencies:
    commandBus: 'Space.messaging.CommandBus'
    eventBus: 'Space.messaging.EventBus'
    eventSourcingConfig: 'Space.eventSourcing.Configuration'
    Mongo: 'Mongo'

  Configuration: {
    useSnapshotting: true
  }

  Singletons: [
    'CustomerApp.CustomerRegistrationRouter'
    'CustomerApp.CustomerRouter'
    'CustomerApp.EmailRouter'
    'CustomerApp.CustomerRegistrationProjection'
  ]

  configure: ->
    @injector.map('CustomerApp.CustomerRegistrations').to new @Mongo.Collection(null)
    if @Configuration.useSnapshotting
      @snapshots = new @Mongo.Collection(null)
      @snapshotter = new Space.eventSourcing.Snapshotter {
        collection: @snapshots
        versionFrequency: 2
      }

  startup: ->
    @reset()
    if @Configuration.useSnapshotting
      @injector.get('Space.eventSourcing.Repository').useSnapshotter @snapshotter

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

  @FIELDS: name: null

  @handle CustomerApp.CreateCustomer, (command) ->
    @record new CustomerApp.CustomerCreated {
      sourceId: @getId()
      customerName: command.name
    }

  @handle CustomerApp.CustomerCreated, (event) -> @name = event.customerName

# -------------- PROCESSES ---------------

class CustomerApp.CustomerRegistration extends Space.eventSourcing.Process

  @FIELDS: {
    customerId: null
    customerName: null
  }

  @STATES: {
    creatingCustomer: 0
    sendingWelcomeEmail: 1
    completed: 2
  }

  @handle CustomerApp.RegisterCustomer, (command) ->

    @trigger new CustomerApp.CreateCustomer
      targetId: command.customerId
      name: command.customerName

    @record new CustomerApp.RegistrationInitiated
      sourceId: @getId()
      customerId: command.customerId
      customerName: command.customerName

  @handle CustomerApp.HandleNewCustomer, (command) ->

    @trigger new CustomerApp.SendWelcomeEmail
      targetId: @customerId
      customerId: command.customerId
      customerName: @customerName

    @record new CustomerApp.WelcomeEmailTriggered
      sourceId: @getId()
      customerId: @customerId

  @handle CustomerApp.MarkRegistrationAsComplete, (command) ->
    @record new CustomerApp.RegistrationCompleted sourceId: @getId()

  @handle CustomerApp.RegistrationInitiated, (event) ->
    { @customerId, @customerName } = event
    @_state = CustomerApp.CustomerRegistration.STATES.creatingCustomer

  @handle CustomerApp.WelcomeEmailTriggered, ->
    @_state = CustomerApp.CustomerRegistration.STATES.sendingWelcomeEmail

  @handle CustomerApp.RegistrationCompleted, ->
    @_state = CustomerApp.CustomerRegistration.STATES.completed

# -------------- ROUTERS --------------- #

class CustomerApp.CustomerRegistrationRouter extends Space.eventSourcing.Router

  Dependencies: {
    registrations: 'CustomerApp.CustomerRegistrations'
  }

  Aggregate: CustomerApp.CustomerRegistration

  InitializingCommand: CustomerApp.RegisterCustomer

  RouteCommands: [
    CustomerApp.HandleNewCustomer
    CustomerApp.MarkRegistrationAsComplete
  ]

  @mapEvent CustomerApp.CustomerCreated, (event) -> new CustomerApp.HandleNewCustomer {
    targetId: @_findRegistrationIdByCustomerId event.sourceId
    customerId: event.sourceId
  }

  @mapEvent CustomerApp.WelcomeEmailSent, (event) ->
    new CustomerApp.MarkRegistrationAsComplete {
      targetId: @_findRegistrationIdByCustomerId event.customerId
    }

  _findRegistrationIdByCustomerId: (customerId) ->
    @registrations.findOne(customerId: customerId)._id

class CustomerApp.CustomerRouter extends Space.eventSourcing.Router

  Aggregate: CustomerApp.Customer
  InitializingCommand: CustomerApp.CreateCustomer

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

# -------------- VIEW PROJECTIONS --------------- #

class CustomerApp.CustomerRegistrationProjection extends Space.messaging.Controller

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
