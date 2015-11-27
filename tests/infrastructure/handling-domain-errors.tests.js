describe("Space.eventSourcing - Handling domain errors", function() {

  it("publishes them as exception event", function() {
    let registrationId = 'reg123';
    CustomerApp.test(CustomerApp.Customer)
    .given(
      new CustomerApp.RegisterCustomer({
        targetId: registrationId,
        customerId: 'cust123',
        customerName: 'MyStrangeCustomerName'
      })
    )
    .expect([
      new Space.domain.Exception({
        thrower: 'CustomerApp.CustomerRegistration',
        error: new CustomerApp.InvalidCustomerName('MyStrangeCustomerName')
      })
    ]);
  });

});
