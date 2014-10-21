
# ============== INTEGRATION SETUP =============== #

class @CustomerApp extends Space.Application

  RequiredModules: ['Space.cqrs']

  Dependencies:
    commandBus: 'Space.cqrs.CommandBus'
    eventBus: 'Space.cqrs.EventBus'
    aggregateRepository: 'Space.cqrs.AggregateRepository'
    eventsCollection: 'Space.cqrs.EventsCollection'

  configure: ->
    @commandBus.registerHandler CustomerApp.CreateCustomer, @_createCustomer
    @commandBus.registerHandler CustomerApp.ChangeCustomerName, @_changeCustomerName

  sendCommand: -> @commandBus.send.apply @commandBus, arguments

  subscribeTo: -> @eventBus.subscribe.apply @eventBus, arguments

  resetDatabase: -> @eventsCollection._collection.remove {}

  _createCustomer: (command) =>

    customer = new Customer command.customerId, command
    @aggregateRepository.create customer

  _changeCustomerName: (command) =>

    customer = @aggregateRepository.find Customer, command.customerId
    customer.changeName command.name

    @aggregateRepository.save customer, command.version

class CustomerApp.CreateCustomer

  @toString: -> 'CustomerApp.CreateCustomer'
  constructor: (data) -> { @customerId, @version, @name } = data

class CustomerApp.ChangeCustomerName

  @toString: -> 'CustomerApp.ChangeCustomerName'
  constructor: (data) -> { @customerId, @version, @name } = data

class CustomerApp.CustomerCreated extends Space.cqrs.DomainEvent

  @toString: -> 'CustomerApp.CustomerCreated'

  constructor: (params) ->
    params.type = CustomerCreated
    super params

class CustomerApp.CustomerNameChanged extends Space.cqrs.DomainEvent

  @toString: -> 'CustomerApp.CustomerNameChanged'

  constructor: (params) ->
    params.type = CustomerNameChanged
    super params

class Customer extends Space.cqrs.AggregateRoot

  name: null

  constructor: (id, data) ->

    super(id)

    @mapEvents(
      CustomerApp.CustomerCreated, @_applyCustomerCreated
      CustomerApp.CustomerNameChanged, @_applyCustomerNameChanged
    )

    if @isHistory data then @loadHistory data
    else
      # new customer
      @applyEvent new CustomerApp.CustomerCreated {
        sourceId: id
        data:
          name: data.name
      }

  changeName: (name) ->

    @applyEvent new CustomerApp.CustomerNameChanged {
      sourceId: @getId()
      data:
        name: name
    }

  _applyCustomerCreated: (event) -> @name = event.data.name

  _applyCustomerNameChanged: (event) -> @name = event.data.name

# ============== INTEGRATION TESTING =============== #

describe.server 'Space.cqrs (integration)', ->

  # commands
  CreateCustomer = CustomerApp.CreateCustomer
  ChangeCustomerName = CustomerApp.ChangeCustomerName

  # events
  CustomerCreated = CustomerApp.CustomerCreated
  CustomerNameChanged = CustomerApp.CustomerNameChanged

  # fixture
  customer =
    customerId: '123'
    name: 'Dominik'

  newName = 'Robocop'

  beforeEach ->
    @app = new CustomerApp()
    @app.resetDatabase()

  it 'handles commands and publishes events correctly', ->

    customerCreatedSpy = sinon.spy()
    customerNameChangedSpy = sinon.spy()

    @app.subscribeTo CustomerCreated, customerCreatedSpy
    @app.subscribeTo CustomerNameChanged, customerNameChangedSpy

    @app.sendCommand CreateCustomer, new CreateCustomer {
      customerId: customer.customerId
      version: 0
      name: customer.name
    }

    expect(customerCreatedSpy).to.have.been.calledWithMatch new CustomerCreated {
      sourceId: customer.customerId
      version: 1
      data:
        name: customer.name
    }

    @app.sendCommand ChangeCustomerName, new ChangeCustomerName {
      customerId: customer.customerId
      version: 1
      name: newName
    }

    expect(customerNameChangedSpy).to.have.been.calledWithMatch new CustomerNameChanged {
      sourceId: customer.customerId
      version: 2
      data:
        name: newName
    }