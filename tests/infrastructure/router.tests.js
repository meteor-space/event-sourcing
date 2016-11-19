describe("Space.eventSourcing.Router", function() {

  beforeEach(function() {
    this.registrationId = 'registration123';
    this.customerId = 'customer543';
    this.app = new Test.App();
    this.app.reset();
  });

  it("invokes the commandBus send callback with no arguments to acknowledge success of an initiating command", function() {
    let callback = sinon.spy();
    this.app.start();
    this.app.send(new Test.RegisterCustomer({
      targetId: this.registrationId,
      customerId: this.customerId,
      customerName: 'MyValidCustomerName'
    }), callback);
    expect(callback).to.have.been.calledWithExactly();
  });

  it("invokes the commandBus send callback when a domain exception occurs with the error as the first argument ", function() {
    let callback = sinon.spy();
    let error = new Test.InvalidCustomerName('MyInvalidCustomerName');
    this.app.start();
    this.app.send(new Test.RegisterCustomer({
      targetId: this.registrationId,
      customerId: this.customerId,
      customerName: 'MyInvalidCustomerName'
    }), callback);
    expect(callback).to.have.been.calledWithExactly(error);
  });

});
