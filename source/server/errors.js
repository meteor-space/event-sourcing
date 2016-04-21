Space.Error.extend('Space.eventSourcing.CommitConcurrencyException', {
  Constructor(aggregateId, expectedVersion, currentVersion) {
    Space.Error.call(this, `Expected entity ${aggregateId} to be at version in ${expectedVersion} but is at version ${currentVersion}`);
  }
});

Space.Error.extend('Space.eventSourcing.ProjectionAlreadyRebuilding', {
  Constructor(name) {
    Space.Error.call(this, `Projection ${name} is already being rebuilt`);
  }
});

Space.Error.extend('Space.eventSourcing.ProjectionNotRebuilding', {
  Constructor(name) {
    Space.Error.call(this, `Expected projection ${name} to be in a state of rebuilding`);
  }
});
