describe("Space.eventSourcing.Aggregate - dependency injection", function() {

  beforeEach(function (){
    CustomerApp.myCommandDependency = sinon.spy();
    CustomerApp.myEventDependency = sinon.spy();

    this.app = new CustomerApp();
    this.app.reset();
  });

  it("injects dependency into new aggregate", function() {
    let command = new CustomerApp.CreateCustomer({
      targetId: new Guid(),
      name: 'MyStrangeCustomerName'
    });

    let app = new CustomerApp();
    app.start();
    app.commandBus.send(command);

    expect(CustomerApp.myCommandDependency).to.have.been.calledOnce;
    expect(CustomerApp.myEventDependency).to.have.been.calledOnce;
  });

  it("injects dependency into existing aggregate", function() {
    customerId = new Guid()
    let createCommand = new CustomerApp.CreateCustomer({
      targetId: customerId,
      name: 'MyStrangeCustomerName'
    });
    let changeCommand = new CustomerApp.ChangeCustomerName({
      targetId: customerId,
      name: 'MyEvenStrangerCustomerName'
    });

    let app = new CustomerApp();
    app.start();
    app.commandBus.send(createCommand);
    app.commandBus.send(changeCommand);

    expect(CustomerApp.myCommandDependency).to.have.been.calledTwice;
    expect(CustomerApp.myEventDependency).to.have.been.calledTwice;
  });
});

describe("Space.eventSourcing.Process - dependency injection", function() {

  beforeEach(function (){
    CustomerApp.myCommandDependency = sinon.spy();
    CustomerApp.myEventDependency = sinon.spy();

    this.registrationId = 'registration123';
    this.customerId = 'customer543';
    this.customerName = 'TestName';

    this.app = new CustomerApp();
    this.app.reset();
  });

  it("injects dependency into process", function() {
    let command = new CustomerApp.CreateCustomer({
      targetId: new Guid(),
      name: 'MyStrangeCustomerName'
    });

    let app = new CustomerApp();
    app.start();
    app.commandBus.send(command);

    expect(CustomerApp.myCommandDependency).to.have.been.calledOnce;
    expect(CustomerApp.myEventDependency).to.have.been.called;
  });
});