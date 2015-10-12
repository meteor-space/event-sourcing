describe 'Space.eventSourcing - messaging', ->

  customer = id: 'customer_123', name: 'Dominik'
  registration = id: 'registration_123'

  beforeEach ->
    @app = new CustomerApp Configuration: { appId: 'CustomerApp' }
    @app.start()

  afterEach ->
    @app.reset()

  it 'handles messages within one app correctly', (test, done) ->

    @app.given(
      new CustomerApp.RegisterCustomer {
        targetId: registration.id
        customerId: customer.id
        customerName: customer.name
      }
    )
    .expect([
      new CustomerApp.RegistrationInitiated({
        sourceId: registration.id
        version: 1
        timestamp: new Date()
        customerId: customer.id
        customerName: customer.name
      })
      new CustomerApp.CustomerCreated({
        sourceId: customer.id
        version: 1
        timestamp: new Date()
        customerName: customer.name
      })
      new CustomerApp.WelcomeEmailTriggered({
        sourceId: registration.id
        version: 2
        timestamp: new Date()
        customerId: customer.id
      })
      new CustomerApp.WelcomeEmailSent({
        sourceId: '999'
        version: 1
        timestamp: new Date()
        email: "Hello #{customer.name}"
        customerId: customer.id
      })
      new CustomerApp.RegistrationCompleted({
        sourceId: registration.id
        version: 3
        timestamp: new Date()
      })
    ])
    .run(done)
