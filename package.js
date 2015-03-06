Package.describe({
  summary: 'CQRS and Event Sourcing Infrastructure for Meteor.',
  name: 'space:cqrs',
  version: '2.3.2',
  git: 'https://github.com/CodeAdventure/space-cqrs.git',
});

Package.onUse(function(api) {

  api.versionsFrom("METEOR@1.0");

  api.use([
    'coffeescript',
    'ejson',
    'space:base@1.2.8',
    'space:messaging@0.1.0'
  ]);

  api.addFiles(['source/server.coffee'], 'server');

  // ========= SHARED =========

  api.addFiles(['source/client.coffee']);
  api.addFiles(['source/domain/value_object.coffee']);

  // ========= server =========

  api.addFiles([
    'source/configuration.coffee',
    // INFRASTRUCTURE
    'source/infrastructure/aggregate_repository.coffee',
    'source/infrastructure/process_manager_repository.coffee',
    'source/infrastructure/commit_collection.coffee',
    'source/infrastructure/commit_store.coffee',
    'source/infrastructure/commit_publisher.coffee',
    // DOMAIN
    'source/domain/aggregate.coffee',
    'source/domain/process_manager.coffee',

  ], 'server');

});

Package.onTest(function(api) {

  api.use([
    'coffeescript',
    'space:cqrs',
    'practicalmeteor:munit@2.0.2',
    'space:testing@1.3.0'
  ]);

  api.addFiles([
    // DOMAIN
    'tests/domain/aggregate.unit.coffee',
    'tests/domain/process_manager.unit.coffee',
    // INFRASTRUCTURE
    'tests/infrastructure/commit_collection.unit.coffee',
    'tests/infrastructure/commit_store.unit.coffee',
    'tests/infrastructure/commit_publisher.unit.coffee',
    // MODULE
    'tests/server_module.integration.coffee',
  ], 'server');

});
