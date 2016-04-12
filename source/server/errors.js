Space.Error.extend('Space.eventSourcing.CommitConcurrencyException', {
  Constructor(aggregateId, expectedVersion, currentVersion) {
    Space.Error.call(this, `Expected entity ${aggregateId} to be at version in ${expectedVersion} but is at version ${currentVersion}`);
  }
});
