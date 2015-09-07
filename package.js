Package.describe({
  summary: 'Event Sourcing Infrastructure for Meteor.',
  name: 'space:event-sourcing',
  version: '1.0.0',
  git: 'https://github.com/meteor-space/event-sourcing.git',
});

Package.onUse(function(api) {

  api.versionsFrom("METEOR@1.0");

  api.use([
    'coffeescript',
    'space:base@2.3.1',
    'space:messaging@1.6.0'
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
    // DOMAIN
    'source/domain/aggregate.coffee',
    'source/domain/process.coffee',

  ], 'server');

});

Package.onTest(function(api) {

  api.use([
    'coffeescript',
    'check',
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
    // MODULE
    'tests/server_module.integration.coffee',
  ], 'server');

});
