describe("Space.eventSourcing - snapshotting", function() {

  beforeEach(function() {
    this.registrationId = 'registration123';
    this.customerId = 'customer543';
    this.customerName = 'TestName';
    this.customerNewName = 'NewTestName';
    this.app = new Test.App();
    this.app.reset();
  });

  it("generates correct snapshots", function() {
    this.app.start();
    this.app.send(new Test.RegisterCustomer({
      targetId: this.registrationId,
      customerId: this.customerId,
      customerName: this.customerName
    }));
    const expectedCustomerRegSnapshot = {
      id: 'registration123',
      version: 3,
      state: 'completed',
      customerId: this.customerId,
      customerName: this.customerName
    };
    const expectedCustomerSnapshot = {
      id: this.customerId,
      version: 2,
      state: null,
      name: this.customerNewName
    };
    let snapshots = this.app.injector.get('Space.eventSourcing.Snapshots').find().fetch();
    expect(snapshots.length).to.equal(1);
    let firstSnapshot = EJSON.parse(snapshots[0].snapshot);
    expect(firstSnapshot).toMatch(expectedCustomerRegSnapshot);

    // Now another command to move the Customer Aggregate to v2
    this.app.send(new Test.ChangeCustomerName({
      targetId: this.customerId,
      name: this.customerNewName
    }));
    snapshots = this.app.injector.get('Space.eventSourcing.Snapshots').find().fetch();
    expect(snapshots.length).to.equal(2);
    firstSnapshot = EJSON.parse(snapshots[0].snapshot);
    let secondSnapshot = EJSON.parse(snapshots[1].snapshot);
    expect(firstSnapshot).toMatch(expectedCustomerRegSnapshot);
    expect(secondSnapshot).toMatch(expectedCustomerSnapshot);
  });

});
