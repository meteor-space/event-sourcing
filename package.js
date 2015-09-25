Package.describe({
  summary: 'Event Sourcing Infrastructure for Meteor.',
  name: 'space:event-sourcing',
  version: '1.3.3',
  git: 'https://github.com/meteor-space/event-sourcing.git',
});

Package.onUse(function(api) {

  api.versionsFrom("METEOR@1.0");

  api.use([
    'coffeescript',
    'ejson',
    'underscore',
    'check',
    'mikowals:batch-insert@1.1.9',
    'space:base@2.4.2',
    'space:messaging@1.7.1'
  ]);

  api.addFiles(['source/server.coffee'], 'server');

  // ========= server =========

  api.addFiles([
    'source/configuration.coffee',
    // INFRASTRUCTURE
    'source/infrastructure/repository.coffee',
    'source/infrastructure/snapshotter.coffee',
    'source/infrastructure/commit_store.coffee',
    'source/infrastructure/commit_publisher.coffee',
    'source/infrastructure/projection.coffee',
    'source/infrastructure/projector.coffee',
    'source/infrastructure/router.coffee',
    // DOMAIN
    'source/domain/aggregate.coffee',
    'source/domain/process.coffee',
  ], 'server');

  // SHARED
  api.addFiles([
    // VALUE OBJECTS
    'source/value-objects/guid.coffee'
  ]);

});

Package.onTest(function(api) {

  api.use([
    'coffeescript',
    'check',
    'ejson',
    'mongo',
    'space:event-sourcing',
    'practicalmeteor:munit@2.1.4',
    'space:testing@1.3.0'
  ]);

  api.addFiles([
    // DOMAIN
    'tests/domain/aggregate.unit.coffee',
    'tests/domain/process.unit.coffee',
    // INFRASTRUCTURE
    'tests/infrastructure/commit_store.unit.coffee',
    'tests/infrastructure/commit_publisher.unit.coffee',
    'tests/infrastructure/repository.unit.coffee',
    'tests/infrastructure/snapshotter.unit.coffee',
    'tests/infrastructure/projection.unit.coffee',
    'tests/infrastructure/router.integration.coffee',
    'tests/infrastructure/projector.integration.coffee',
    // MODULE
    'tests/server_module.integration.coffee',
    // VALUE OBJECTS
    'tests/value-objects/guid.unit.coffee'
  ], 'server');

});
