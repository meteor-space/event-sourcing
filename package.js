Package.describe({
  summary: 'Event Sourcing Infrastructure for Meteor.',
  name: 'space:event-sourcing',
  version: '3.1.0',
  git: 'https://github.com/meteor-space/event-sourcing.git'
});

Package.onUse(function(api) {

  api.versionsFrom('1.4.2.1');

  api.use([
    'coffeescript',
    'ejson',
    'underscore',
    'check',
    'mongo',
    'ecmascript',
    'mikowals:batch-insert@1.1.14',
    'fongandrew:find-and-modify@1.0.0',
    'space:base@4.1.3',
    'space:messaging@3.3.1',
  ]);

  // ========= server =========

  api.addFiles([
    'source/server/module-automation.js',
    'source/server/module.coffee',
    'source/server/errors.js',
    // INFRASTRUCTURE
    'source/server/infrastructure/repository.coffee',
    'source/server/infrastructure/snapshot.js',
    'source/server/infrastructure/snapshotter.coffee',
    'source/server/infrastructure/commit_store.coffee',
    'source/server/infrastructure/commit_publisher.coffee',
    'source/server/infrastructure/projection.coffee',
    'source/server/infrastructure/projection-rebuilder.coffee',
    'source/server/infrastructure/router.coffee',
    // DOMAIN
    'source/server/domain/aggregate.coffee',
    'source/server/domain/process.coffee'
  ], 'server');

});

Package.onTest(function(api) {

  api.use([
    'coffeescript',
    'check',
    'ejson',
    'mongo',
    'underscore',
    'ecmascript',
    'space:event-sourcing',
    'space:testing@3.0.2',
    'space:testing-messaging@3.0.1',
    'space:testing-event-sourcing@3.1.0',
    'practicalmeteor:munit@2.1.5'
  ], 'server');

  api.addFiles([
    // HELPERS
    'tests/test-application.js',
    // DOMAIN
    'tests/domain/aggregate.unit.coffee',
    'tests/domain/process.unit.coffee',
    // INFRASTRUCTURE
    'tests/infrastructure/repository.unit.coffee',
    'tests/infrastructure/commit_store.unit.coffee',
    'tests/infrastructure/commit_publisher.unit.coffee',
    'tests/infrastructure/router.unit.coffee',
    'tests/infrastructure/router.tests.js',
    'tests/infrastructure/snapshotter.unit.coffee',
    'tests/infrastructure/snapshotting.tests.js',
    'tests/infrastructure/projection.unit.coffee',
    'tests/infrastructure/projection-rebuilder.tests.coffee',
    'tests/infrastructure/messaging.tests.coffee',
    'tests/infrastructure/handling-domain-errors.tests.js',
    // INTEGRATION
    'tests/integration/event-sourceable-dependency-injection.js'
  ], 'server');

});
