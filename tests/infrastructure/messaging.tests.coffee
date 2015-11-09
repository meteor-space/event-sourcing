describe 'Space.eventSourcing - messaging', ->

  customer = id: 'customer_123', name: 'Dominik'
  registration = id: 'registration_123'

  generatedEventsForCustomerRegistration = -> [

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
    # This is just visible in the app that runs the code
    # since it is directly published via the event store
    # instead of saved to the DB as part of a commit!
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
  ]

  it 'handles messages within one app correctly', (test, done) ->

    CustomerApp.test(CustomerApp.Customer)
    .given(
      new CustomerApp.RegisterCustomer {
        targetId: registration.id
        customerId: customer.id
        customerName: customer.name
      }
    )
    .expect(generatedEventsForCustomerRegistration())

  it 'supports distributed messaging via a shared commits collection', (test, done) ->

    secondApp = Space.Application.create RequiredModules: ['Space.eventSourcing']
    secondApp.configure {
      appId: 'SecondApp'
    }
    secondApp.start()
    # Aggregate all published events on the second app
    publishedEvents = []
    secondApp.eventBus.onPublish (event) -> publishedEvents.push event
    expectedEvents = null

    CustomerApp.test(CustomerApp.Customer)
    .given(
      new CustomerApp.RegisterCustomer {
        targetId: registration.id
        customerId: customer.id
        customerName: customer.name
      }
    )
    .expect(->
      expectedEvents = generatedEventsForCustomerRegistration()
      return expectedEvents
    )

    Meteor.setTimeout (done =>
      # Remove the event that is only visible to the other app
      # because it is directly published on its event bus!
      expectedEvents.splice(3,1)
      expect(publishedEvents).toMatch expectedEvents
      secondApp.stop()
    ), 100
